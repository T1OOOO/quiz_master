library;

import 'fact_practice.dart';

import 'russian_learning_text.dart';

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import 'organ_atlas_models.dart';
import 'map_interaction.dart';
import 'anatomy_scene.dart';

Future<OrganAtlas> loadOrganAtlas([AssetBundle? bundle]) async {
  final raw = await (bundle ?? rootBundle).loadString(organAtlasAsset);
  return OrganAtlas.fromJson(Map<String, dynamic>.from(jsonDecode(raw) as Map));
}

/// The x/y basis scale; Matrix4.getMaxScaleOnAxis also includes the unchanged z
/// basis and therefore cannot tell whether a 2D map has zoomed out.
double organAtlasCameraScale(Matrix4 matrix) => matrix.storage[0].abs();

/// A route can choose a truthful catalogue without loading a second anatomy
/// asset. The data remains the retained, source-linked registry.
enum OrganAtlasScope { all, organs, bones, brain, systems }

class OrganAtlasPage extends StatefulWidget {
  const OrganAtlasPage({
    super.key,
    this.bundle,
    this.training = false,
    this.initialScope = OrganAtlasScope.all,
  });
  final AssetBundle? bundle;
  final bool training;
  final OrganAtlasScope initialScope;
  @override
  State<OrganAtlasPage> createState() => _OrganAtlasPageState();
}

class _OrganAtlasPageState extends State<OrganAtlasPage> {
  late Future<OrganAtlas> _future = _load();
  bool _initialTrainingStarted = false;
  int _originalTotal = 0;
  Future<OrganAtlas> _load() async {
    final atlas = await loadOrganAtlas(widget.bundle);
    if (widget.training && !_initialTrainingStarted) {
      _round = atlas.round(
        seed: _seed++,
        count: 10,
        allowedIds: atlas.organs.where(_inScope).map((item) => item.id),
      );
      _originalTotal = _round.length;
      _finished = _round.isEmpty;
      _initialTrainingStarted = true;
    }
    return atlas;
  }

  final _search = TextEditingController();
  final _camera = TransformationController();
  String _region = '', _system = '', _kind = '';
  Set<String>? _sceneIds;
  OrganStructure? _selected;
  bool _endocrineView = false;
  bool _training = false, _checked = false, _finished = false, _review = false;
  List<OrganQuestion> _round = [], _missed = [];
  int _index = 0, _score = 0, _seed = 31;
  String? _answer;
  @override
  void initState() {
    super.initState();
    _training = widget.training;
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    _camera.dispose();
    super.dispose();
  }

  bool get _ru => Localizations.localeOf(context).languageCode == 'ru';
  String _t(String en, String ru) => _ru ? ru : en;
  String _name(OrganStructure item) => _ru ? item.nameRu : item.nameEn;
  String _v(String en, String ru) => _ru ? russianLearningText(ru) : en;
  void _reset() => setState(() => _camera.value = Matrix4.identity());
  void _zoom(double value) {
    final next = Matrix4.copy(_camera.value)..scaleByDouble(value, value, 1, 1);
    if (organAtlasCameraScale(next) >= .6 && organAtlasCameraScale(next) <= 5) {
      setState(() => _camera.value = next);
    }
  }

  void _select(OrganStructure value) {
    setState(() => _selected = value);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: .78,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
          child: _Detail(item: value, atlas: _loadedAtlas!, russian: _ru),
        ),
      ),
    );
  }

  OrganAtlas? _loadedAtlas;
  bool _inScope(OrganStructure item) => switch (widget.initialScope) {
    OrganAtlasScope.all => true,
    OrganAtlasScope.organs =>
      item.kind != 'bone' &&
          item.kind != 'bone_group' &&
          item.kind != 'brain_region',
    OrganAtlasScope.bones => item.kind == 'bone' || item.kind == 'bone_group',
    OrganAtlasScope.brain => item.kind == 'brain_region',
    OrganAtlasScope.systems => true,
  };

  String _scopeTitle() => switch (widget.initialScope) {
    OrganAtlasScope.all => _t('Human anatomy atlas', 'Атлас анатомии'),
    OrganAtlasScope.organs => _t('Organs and glands', 'Органы и железы'),
    OrganAtlasScope.bones => _t('Bone catalogue', 'Каталог костей'),
    OrganAtlasScope.brain => _t('Brain regions', 'Отделы мозга'),
    OrganAtlasScope.systems => _t('Body systems', 'Системы организма'),
  };

  String _scopeDirectoryTitle() => switch (widget.initialScope) {
    OrganAtlasScope.all => _t('All structures', 'Все структуры'),
    OrganAtlasScope.organs => _t('Organs and glands', 'Органы и железы'),
    OrganAtlasScope.bones => _t('206 bones', '206 костей'),
    OrganAtlasScope.brain => _t('Brain regions', 'Отделы мозга'),
    OrganAtlasScope.systems => _t(
      'Structures by body system',
      'Структуры по системам',
    ),
  };

  String _scopeDirectorySubtitle() => switch (widget.initialScope) {
    OrganAtlasScope.all => _t(
      'Organs, glands, bones and brain regions',
      'Органы, железы, кости и отделы мозга',
    ),
    OrganAtlasScope.organs => _t(
      'Major organs and named glandular structures',
      'Крупные органы и именованные железистые структуры',
    ),
    OrganAtlasScope.bones => _t(
      'Tap a visible region to filter the list of bones.',
      'Нажмите на видимую область, чтобы отфильтровать список костей.',
    ),
    OrganAtlasScope.brain => _t(
      'Tap a visible region or browse all brain cards.',
      'Нажмите на видимый отдел или просмотрите все карточки мозга.',
    ),
    OrganAtlasScope.systems => _t(
      'Each item appears under its recorded system or systems',
      'Каждый объект показан в записанной для него системе или системах',
    ),
  };

  List<OrganStructure> _visible(OrganAtlas atlas) {
    final query = _search.text.trim().toLowerCase();
    return atlas.organs.where((item) {
      final words =
          '${item.nameEn} ${item.nameRu} ${item.nameLa ?? ''} ${item.functionEn} ${item.functionRu} ${item.systemIds.join(' ')} ${item.kind} ${item.region}'
              .toLowerCase();
      return _inScope(item) &&
          (_sceneIds == null || _sceneIds!.contains(item.id)) &&
          (_region.isEmpty || item.region == _region) &&
          (_kind.isEmpty || item.kind == _kind) &&
          (_system.isEmpty || item.systemIds.contains(_system)) &&
          words.contains(query);
    }).toList()..sort((a, b) => _name(a).compareTo(_name(b)));
  }

  void _start(
    OrganAtlas atlas,
    List<OrganStructure> visible, {
    List<OrganQuestion>? retry,
  }) {
    final round =
        retry ??
        atlas.round(
          seed: _seed++,
          count: 10,
          allowedIds: visible.map((item) => item.id),
        );
    if (retry == null && round.isEmpty && visible.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => FactPracticePage(
            scope: 'organs',
            bundle: widget.bundle,
            entityIds: visible.map((item) => item.id).toSet(),
          ),
        ),
      );
      return;
    }
    setState(() {
      _round = round;
      _training = true;
      _index = 0;
      if (retry == null) {
        _score = 0;
        _originalTotal = _round.length;
      }
      _checked = false;
      _finished = _round.isEmpty;
      _answer = null;
      if (retry == null) {
        _missed = [];
        _review = false;
      }
    });
  }

  void _check() => setState(() {
    if (_answer == null || _checked) return;
    _checked = true;
    final q = _round[_index];
    if (_answer == q.correctId && !_review) _score++;
    if (_answer != q.correctId && !_review) _missed.add(q);
  });
  void _next() => setState(() {
    if (_index + 1 >= _round.length) {
      _finished = true;
    } else {
      _index++;
      _checked = false;
      _answer = null;
    }
  });

  String _choiceExplanation(OrganStructure item) {
    final position = _v(item.positionEn, item.positionRu).trim();
    final function = _v(item.functionEn, item.functionRu).trim();
    if (position.isEmpty && function.isEmpty) return '';
    return [
      if (position.isNotEmpty) '${_t('Position', 'Положение')}: $position',
      if (function.isNotEmpty) '${_t('Function', 'Функция')}: $function',
    ].join('\n');
  }

  Widget _answerSummary({
    required Key key,
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) => Card(
    key: key,
    color: color,
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon),
          const SizedBox(width: 8),
          Expanded(child: Text('$label: $value')),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<OrganAtlas>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return _shell(const Center(child: CircularProgressIndicator()));
      }
      if (snapshot.hasError) {
        return _shell(
          _Notice(
            _t('The atlas could not load.', 'Атлас не удалось загрузить.'),
            _t('Retry', 'Повторить'),
            () => setState(() => _future = _load()),
          ),
        );
      }
      final atlas = snapshot.data!;
      _loadedAtlas = atlas;
      if (atlas.organs.isEmpty) {
        return _shell(
          _Notice(
            _t(
              'No structures are available yet.',
              'Структуры пока не добавлены.',
            ),
            _t('Retry', 'Повторить'),
            () => setState(() => _future = _load()),
          ),
        );
      }
      return _training ? _quiz(atlas) : _browse(atlas);
    },
  );
  Widget _shell(Widget child) => Scaffold(
    appBar: AppBar(title: Text(_scopeTitle())),
    body: SafeArea(child: child),
  );
  Widget _browse(OrganAtlas atlas) {
    final shown = _visible(atlas);
    final regions = shown.map((item) => item.region).toSet().toList()..sort();
    final systems = shown.expand((item) => item.systemIds).toSet().toList()
      ..sort();
    final kinds = shown.map((item) => item.kind).toSet().toList()..sort();
    final searching =
        _search.text.trim().isNotEmpty ||
        _region.isNotEmpty ||
        _system.isNotEmpty ||
        _kind.isNotEmpty ||
        _sceneIds != null;
    final rows = [
      for (final item in shown)
        ListTile(
          key: Key('organ-list-${item.id}'),
          title: Text(_name(item)),
          subtitle: Text(_filterLabel(context, item.kind)),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _select(item),
        ),
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text(_scopeTitle()),
        actions: [
          FactPracticeAction(
            scope: 'organs',
            bundle: widget.bundle,
            entityIds: shown.map((item) => item.id).toSet(),
          ),
          IconButton(
            tooltip: _t('Anatomy questions', switch (widget.initialScope) {
              OrganAtlasScope.bones => 'Вопросы о костях',
              OrganAtlasScope.brain => 'Вопросы о мозге',
              OrganAtlasScope.systems => 'Вопросы о системах организма',
              _ => 'Вопросы об органах',
            }),
            onPressed: () => _start(atlas, shown),
            icon: const Icon(Icons.quiz_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: MapScrollView(
          key: const Key('organ-scroll'),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.initialScope == OrganAtlasScope.all ||
                  widget.initialScope == OrganAtlasScope.organs) ...[
                Wrap(
                  key: const Key('organ-view-selector'),
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ChoiceChip(
                      key: const Key('organ-view-anterior'),
                      label: Text(_t('Organs', 'Органы')),
                      selected: !_endocrineView,
                      onSelected: (_) => setState(() => _endocrineView = false),
                    ),
                    ChoiceChip(
                      key: const Key('organ-view-endocrine'),
                      label: Text(_t('Endocrine glands', 'Эндокринные железы')),
                      selected: _endocrineView,
                      onSelected: (_) => setState(() => _endocrineView = true),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_endocrineView)
                  _endocrineScene(atlas)
                else ...[
                  _BodyMap(
                    controller: _camera,
                    organs: shown
                        .where(
                          (item) =>
                              item.kind != 'bone' &&
                              item.kind != 'bone_group' &&
                              item.kind != 'brain_region',
                        )
                        .toList(),
                    selected: _selected,
                    name: _name,
                    onSelected: _select,
                  ),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      IconButton(
                        tooltip: _t('Zoom in', 'Увеличить'),
                        icon: const Icon(Icons.add),
                        onPressed: () => _zoom(1.25),
                      ),
                      IconButton(
                        tooltip: _t('Zoom out', 'Уменьшить'),
                        icon: const Icon(Icons.remove),
                        onPressed: () => _zoom(.8),
                      ),
                      TextButton.icon(
                        onPressed: _reset,
                        icon: const Icon(Icons.center_focus_strong),
                        label: Text(_t('Fit', 'Вся схема')),
                      ),
                    ],
                  ),
                ],
              ],
              if (widget.initialScope == OrganAtlasScope.bones) _boneScene(),
              if (widget.initialScope == OrganAtlasScope.brain) _brainScene(),
              const SizedBox(height: 12),
              TextField(
                key: const Key('organ-search'),
                controller: _search,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: _t(
                    'Search this catalogue',
                    'Поиск по этому каталогу',
                  ),
                ),
              ),
              if (_sceneIds != null || _region.isNotEmpty)
                TextButton.icon(
                  key: const Key('anatomy-show-all'),
                  onPressed: () => setState(() {
                    _sceneIds = null;
                    _region = '';
                  }),
                  icon: const Icon(Icons.clear),
                  label: Text(_t('Show all', 'Показать всё')),
                ),
              ExpansionTile(
                key: const Key('organ-filters'),
                title: Text(_t('Filters', 'Фильтры')),
                children: [
                  _Filters(
                    label: _t('Region', 'Область'),
                    values: regions,
                    selected: _region,
                    onChanged: (v) => setState(() => _region = v),
                  ),
                  _Filters(
                    label: _t('System', 'Система'),
                    values: systems,
                    selected: _system,
                    onChanged: (v) => setState(() => _system = v),
                  ),
                  _Filters(
                    label: _t('Type', 'Тип'),
                    values: kinds,
                    selected: _kind,
                    onChanged: (v) => setState(() => _kind = v),
                  ),
                ],
              ),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _t('No matching structures.', 'Ничего не найдено.'),
                  ),
                ),
              if (searching)
                ...rows
              else
                ExpansionTile(
                  key: widget.initialScope == OrganAtlasScope.all
                      ? const Key('organ-directory')
                      : Key('organ-directory-${widget.initialScope.name}'),
                  initiallyExpanded:
                      widget.initialScope == OrganAtlasScope.systems,
                  title: Text(_scopeDirectoryTitle()),
                  subtitle: Text(_scopeDirectorySubtitle()),
                  trailing: Text('${shown.length}'),
                  children: widget.initialScope == OrganAtlasScope.systems
                      ? _systemGroups(shown)
                      : [
                          if (widget.initialScope == OrganAtlasScope.all)
                            ExpansionTile(
                              key: const Key('organ-system-directory'),
                              title: Text(
                                _t(
                                  'Browse by body system',
                                  'По системам организма',
                                ),
                              ),
                              children: _systemGroups(shown),
                            ),
                          ...rows,
                        ],
                ),
              TextButton.icon(
                icon: const Icon(Icons.info_outline),
                label: Text(_t('About the diagram', 'О схеме и источниках')),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text(_t('About this atlas', 'О схеме')),
                    content: Text(
                      _v(atlas.coverageNoteEn, atlas.coverageNoteRu),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(_t('Close', 'Закрыть')),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _systemGroups(List<OrganStructure> shown) {
    final bySystem = <String, List<OrganStructure>>{};
    for (final item in shown) {
      for (final system in item.systemIds) {
        bySystem.putIfAbsent(system, () => []).add(item);
      }
    }
    final systems = bySystem.keys.toList()..sort();
    return [
      for (final system in systems)
        ExpansionTile(
          key: Key('organ-system-$system'),
          title: Text(_filterLabel(context, system)),
          trailing: Text('${bySystem[system]!.length}'),
          children: [
            for (final item in bySystem[system]!)
              ListTile(
                key: Key('organ-list-${item.id}'),
                title: Text(_name(item)),
                subtitle: Text(_filterLabel(context, item.kind)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _select(item),
              ),
          ],
        ),
    ];
  }

  Widget _endocrineScene(OrganAtlas atlas) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        _t(
          'Main endocrine glands: 8 marked; other glands remain in the catalogue.',
          'Основные эндокринные железы: 8 отметок; остальные железы доступны в каталоге.',
        ),
      ),
      const SizedBox(height: 4),
      Text(
        _t(
          'Male and female reproductive structures are shown side by side schematically.',
          'Мужские и женские репродуктивные структуры показаны рядом схематично.',
        ),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 8),
      AnatomyScene(
        asset: 'assets/quizipedia/endocrine-ru-display.png',
        aspectRatio: 317 / 421,
        markerDiameter: 28,
        credit: const AnatomySceneCredit(
          author: 'Правительство США; исходная иллюстрация NCI SEER; русская версия на Викискладе',
          license: 'Общественное достояние (PD-USGov)',
          source: 'https://commons.wikimedia.org/wiki/File:Illu_endocrine_system_-ru.png',
        ),
        zoomInLabel: _t('Zoom in', 'Увеличить'),
        zoomOutLabel: _t('Zoom out', 'Уменьшить'),
        resetLabel: _t('Fit image', 'Вся схема'),
        creditLabel: _t('Image credit', 'Источник изображения'),
        markers: [
          _marker('pituitary', 'Pituitary', 'Гипофиз', 142 / 317, 90 / 421),
          _marker('pineal', 'Pineal gland', 'Эпифиз', 180 / 317, 77 / 421),
          _marker(
            'thyroid',
            'Thyroid gland',
            'Щитовидная железа',
            142 / 317,
            142 / 421,
          ),
          _marker('thymus', 'Thymus', 'Тимус', 177 / 317, 182 / 421),
          _marker(
            'adrenals',
            'Adrenal glands',
            'Надпочечники',
            124 / 317,
            263 / 421,
          ),
          _marker(
            'pancreas',
            'Pancreas',
            'Поджелудочная железа',
            171 / 317,
            278 / 421,
          ),
          _marker('ovaries', 'Ovaries', 'Яичники', 190 / 317, 324 / 421),
          _marker('testes', 'Testes', 'Яички', 136 / 317, 376 / 421),
        ],
        onMarkerTap: (marker) => _select(atlas.organ(marker.id)),
      ),
    ],
  );

  Widget _boneScene() => AnatomyScene(
    asset: 'assets/quizipedia/skeleton-display.png',
    aspectRatio: 500 / 967,
    credit: const AnatomySceneCredit(
      author: 'Mariana Ruiz Villarreal / Mikael Häggström',
      license: 'Public domain',
      source: 'https://commons.wikimedia.org/wiki/File:Human_skeleton_front_-_no_labels.svg',
    ),
    zoomInLabel: _t('Zoom in', 'Увеличить'),
    zoomOutLabel: _t('Zoom out', 'Уменьшить'),
    resetLabel: _t('Fit image', 'Вся схема'),
    creditLabel: _t('Image credit', 'Источник изображения'),
    markers: [
      _marker('skull', 'Skull', 'Череп', .46, .09),
      _marker('thorax', 'Thorax', 'Грудная клетка', .46, .26),
      _marker('spine', 'Spine', 'Позвоночник', .46, .36),
      _marker('pelvis', 'Pelvis', 'Таз', .46, .44),
      _marker('upper-limb-left', 'Upper limb', 'Верхняя конечность', .25, .32),
      _marker('upper-limb-right', 'Upper limb', 'Верхняя конечность', .75, .32),
      _marker('lower-limb-left', 'Lower limb', 'Нижняя конечность', .39, .68),
      _marker('lower-limb-right', 'Lower limb', 'Нижняя конечность', .55, .68),
    ],
    onMarkerTap: (marker) => setState(() {
      _sceneIds = null;
      _region = switch (marker.id) {
        'skull' => 'head',
        'thorax' => 'thorax',
        'spine' => 'spine',
        'pelvis' => 'pelvis',
        'upper-limb-left' || 'upper-limb-right' => 'upper_limb',
        _ => 'lower_limb',
      };
    }),
  );

  Widget _brainScene() => AnatomyScene(
    asset: 'assets/quizipedia/brain-display.png',
    aspectRatio: 500 / 699,
    credit: const AnatomySceneCredit(
      author: 'Patrick J. Lynch; C. Carl Jaffe, MD',
      license: 'CC BY 2.5',
      source: 'https://commons.wikimedia.org/wiki/File:Skull_and_brain_normal_human.svg',
    ),
    zoomInLabel: _t('Zoom in', 'Увеличить'),
    zoomOutLabel: _t('Zoom out', 'Уменьшить'),
    resetLabel: _t('Fit image', 'Вся схема'),
    creditLabel: _t('Image credit', 'Источник изображения'),
    markers: [
      _marker('frontal', 'Frontal lobe', 'Лобная доля', .25, .16),
      _marker('parietal', 'Parietal lobe', 'Теменная доля', .60, .12),
      _marker('temporal', 'Temporal lobe', 'Височная доля', .50, .33),
      _marker('occipital', 'Occipital lobe', 'Затылочная доля', .86, .24),
      _marker('cerebellum', 'Cerebellum', 'Мозжечок', .77, .40),
    ],
    onMarkerTap: (marker) => setState(() {
      _region = '';
      _sceneIds = {'brain-${marker.id}-lobe'};
      if (marker.id == 'cerebellum') {
        _sceneIds = {'brain-cerebellum', 'cerebellum'};
      }
    }),
  );

  AnatomySceneMarker _marker(
    String id,
    String english,
    String russian,
    double x,
    double y,
  ) => AnatomySceneMarker(id: id, label: _t(english, russian), x: x, y: y);

  Widget _quiz(OrganAtlas atlas) {
    if (_finished || _round.isEmpty) {
      return _shell(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _round.isEmpty
                      ? _t(
                          'No fair questions match these filters.',
                          'Нет подходящих вопросов для этих фильтров.',
                        )
                      : '${_t('Original score', 'Исходный результат')}: $_score/$_originalTotal',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                if (_missed.isNotEmpty && !_review)
                  FilledButton(
                    onPressed: () {
                      setState(() => _review = true);
                      _start(atlas, const [], retry: _missed);
                    },
                    child: Text(
                      _t(
                        'Review mistakes (${_missed.length})',
                        'Разобрать ошибки (${_missed.length})',
                      ),
                    ),
                  ),
                TextButton(
                  onPressed: () => setState(() => _training = false),
                  child: Text(_t('Back to atlas', 'Вернуться к атласу')),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final question = _round[_index];
    final options = question.optionIds.map(atlas.organ).toList();
    final correct = atlas.organ(question.correctId);
    return _shell(
      SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _t(
                'Local unranked practice · ${_index + 1}/${_round.length}',
                'Локальная тренировка без рейтинга · ${_index + 1}/${_round.length}',
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _v(question.stemEn, question.stemRu),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            for (final item in options) ...[
              Builder(
                builder: (context) {
                  final correctOption =
                      _checked && item.id == question.correctId;
                  final wrongSelection =
                      _checked && item.id == _answer && !correctOption;
                  final scheme = Theme.of(context).colorScheme;
                  final icon = correctOption
                      ? Icons.check_circle_outline
                      : wrongSelection
                      ? Icons.cancel_outlined
                      : null;
                  final status = correctOption
                      ? _t('Correct', 'Верный ответ')
                      : wrongSelection
                      ? _t('Your answer', 'Ваш ответ')
                      : null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Semantics(
                      label: status == null
                          ? _name(item)
                          : '$status: ${_name(item)}',
                      child: OutlinedButton(
                        key: Key('organ-option-${item.id}'),
                        onPressed: _checked
                            ? null
                            : () => setState(() => _answer = item.id),
                        style: OutlinedButton.styleFrom(
                          disabledForegroundColor: wrongSelection
                              ? scheme.onErrorContainer
                              : correctOption
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                          disabledBackgroundColor: wrongSelection
                              ? scheme.errorContainer
                              : correctOption
                              ? scheme.primaryContainer
                              : null,
                          minimumSize: const Size(44, 48),
                          backgroundColor: _answer == item.id && !_checked
                              ? scheme.secondaryContainer
                              : null,
                        ),
                        child: Row(
                          children: [
                            if (icon != null) ...[
                              Icon(icon),
                              const SizedBox(width: 8),
                            ],
                            Expanded(child: Text(_name(item))),
                            if (status != null) Text(status),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
            if (!_checked)
              FilledButton(
                key: const Key('organ-check'),
                onPressed: _answer == null ? null : _check,
                child: Text(_t('Check', 'Проверить')),
              ),
            if (_checked) ...[
              _answerSummary(
                key: const Key('organ-feedback-your'),
                icon: _answer == question.correctId
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                label: _t('Your answer', 'Ваш ответ'),
                value: _name(atlas.organ(_answer!)),
                color: _answer == question.correctId
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.errorContainer,
              ),
              if (_answer != question.correctId)
                _answerSummary(
                  key: const Key('organ-feedback-correct'),
                  icon: Icons.check_circle_outline,
                  label: _t('Correct answer', 'Правильный ответ'),
                  value: _name(correct),
                  color: Theme.of(context).colorScheme.primaryContainer,
                ),
              FilledButton(
                key: const Key('organ-next'),
                onPressed: _next,
                child: Text(_t('Next', 'Далее')),
              ),
              Text(
                _answer == question.correctId
                    ? _t('Correct.', 'Верно.')
                    : _t('Not quite.', 'Не совсем.'),
              ),
              Text(_v(question.explanationEn, question.explanationRu)),
              ExpansionTile(
                key: const Key('organ-option-explanations'),
                title: Text(
                  _t('Explanations for the options', 'Пояснения к вариантам'),
                ),
                children: [
                  for (final item in options)
                    if (_choiceExplanation(item).isNotEmpty)
                      ExpansionTile(
                        key: Key('organ-option-explanation-${item.id}'),
                        title: Text(
                          _t('About ${_name(item)}', 'О ${_name(item)}'),
                        ),
                        childrenPadding: const EdgeInsets.fromLTRB(
                          16,
                          0,
                          16,
                          12,
                        ),
                        children: [Text(_choiceExplanation(item))],
                      ),
                ],
              ),
              for (final source in question.sourceIds)
                Text(
                  '${_t('Source', 'Источник')}: ${learningSourceTitle(atlas.source(source).title, russian: _ru)}',
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Filters extends StatelessWidget {
  const _Filters({
    required this.label,
    required this.values,
    required this.selected,
    required this.onChanged,
  });
  final String label, selected;
  final List<String> values;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 6),
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        Text('$label:'),
        ChoiceChip(
          label: Text(
            Localizations.localeOf(context).languageCode == 'ru'
                ? 'Все'
                : 'All',
          ),
          selected: selected.isEmpty,
          onSelected: (_) => onChanged(''),
        ),
        for (final value in values)
          ChoiceChip(
            label: Text(_filterLabel(context, value)),
            selected: selected == value,
            onSelected: (_) => onChanged(value),
          ),
      ],
    ),
  );
}

String _filterLabel(BuildContext context, String value) {
  final ru = Localizations.localeOf(context).languageCode == 'ru';
  const en = {
    'head': 'Head',
    'neck': 'Neck',
    'thorax': 'Chest',
    'abdomen': 'Abdomen',
    'pelvis': 'Pelvis',
    'distributed': 'Distributed',
    'upper_limb': 'Upper limb',
    'lower_limb': 'Lower limb',
    'spine': 'Spine',
    'organ': 'Organ',
    'endocrine_gland': 'Endocrine gland',
    'exocrine_gland': 'Exocrine gland',
    'mixed_gland': 'Mixed gland',
    'gland_group': 'Gland group',
    'endocrine_tissue': 'Endocrine tissue',
    'bone_group': 'Bone group',
    'bone': 'Bone',
    'brain_region': 'Brain region',
    'nervous': 'Nervous system',
    'endocrine': 'Endocrine system',
    'digestive': 'Digestive system',
    'respiratory': 'Respiratory system',
    'cardiovascular': 'Cardiovascular system',
    'urinary': 'Urinary system',
    'reproductive': 'Reproductive system',
    'lymphatic': 'Lymphatic system',
    'integumentary': 'Integumentary system',
    'sensory': 'Sense organs',
    'musculoskeletal': 'Musculoskeletal system',
  };
  const russian = {
    'head': 'Голова',
    'neck': 'Шея',
    'thorax': 'Грудная клетка',
    'abdomen': 'Живот',
    'pelvis': 'Таз',
    'distributed': 'Распределено',
    'upper_limb': 'Верхняя конечность',
    'lower_limb': 'Нижняя конечность',
    'spine': 'Позвоночник',
    'organ': 'Орган',
    'endocrine_gland': 'Эндокринная железа',
    'exocrine_gland': 'Экзокринная железа',
    'mixed_gland': 'Смешанная железа',
    'gland_group': 'Группа желёз',
    'endocrine_tissue': 'Эндокринная ткань',
    'bone_group': 'Группа костей',
    'bone': 'Кость',
    'brain_region': 'Отдел мозга',
    'nervous': 'Нервная',
    'endocrine': 'Эндокринная',
    'digestive': 'Пищеварительная',
    'respiratory': 'Дыхательная',
    'cardiovascular': 'Сердечно-сосудистая',
    'urinary': 'Мочевая',
    'reproductive': 'Репродуктивная',
    'lymphatic': 'Лимфатическая',
    'integumentary': 'Покровная',
    'sensory': 'Органы чувств',
    'musculoskeletal': 'Опорно-двигательная',
  };
  return (ru ? russian : en)[value] ?? value.replaceAll('_', ' ');
}

class _Notice extends StatelessWidget {
  const _Notice(this.title, this.action, this.onAction);
  final String title, action;
  final VoidCallback onAction;
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(title),
        TextButton(onPressed: onAction, child: Text(action)),
      ],
    ),
  );
}

class _BodyMap extends StatefulWidget {
  const _BodyMap({
    required this.controller,
    required this.organs,
    required this.selected,
    required this.name,
    required this.onSelected,
  });
  final TransformationController controller;
  final List<OrganStructure> organs;
  final OrganStructure? selected;
  final String Function(OrganStructure) name;
  final ValueChanged<OrganStructure> onSelected;
  @override
  State<_BodyMap> createState() => _BodyMapState();
}

class _BodyMapState extends State<_BodyMap> {
  // Positions refer to the visible organs in the anterior overview image.
  static const _illustratedAnchors = <String, Offset>{
    'brain': Offset(150, 28),
    'thyroid': Offset(150, 118),
    'lungs': Offset(112, 172),
    'heart': Offset(165, 195),
    'liver': Offset(120, 234),
    'stomach': Offset(177, 250),
    'trachea': Offset(150, 139),
    'small_intestine': Offset(151, 312),
    'large_intestine': Offset(118, 287),
    'gallbladder': Offset(113, 258),
    'bone-right-humerus': Offset(72, 202),
    'bone-left-humerus': Offset(231, 204),
    'bone-right-clavicle': Offset(105, 133),
    'bone-left-clavicle': Offset(193, 133),
  };
  @override
  Widget build(BuildContext context) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final targets = [
      for (final id in _illustratedAnchors.keys)
        ...widget.organs.where((item) => item.id == id),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          ru
              ? 'Нажмите на орган на схеме или выберите его название.'
              : 'Tap an organ on the diagram or choose its name.',
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: (MediaQuery.sizeOf(context).height * .55).clamp(300.0, 450.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: LayoutBuilder(
              builder: (context, box) {
                final scale = (box.maxWidth / 300).clamp(
                  0.0,
                  box.maxHeight / 450,
                );
                final left = (box.maxWidth - 300 * scale) / 2;
                final top = (box.maxHeight - 450 * scale) / 2;
                // Keep raw touch coordinates on Web; named accessible controls are below.
                return Semantics(
                  label: ru
                      ? 'Схема органов: вид спереди'
                      : 'Anterior organ overview',
                  child: ExcludeSemantics(
                    child: MapInteraction(
                      child: InteractiveViewer(
                        key: const Key('organ-map'),
                        transformationController: widget.controller,
                        minScale: .6,
                        maxScale: 5,
                        boundaryMargin: const EdgeInsets.all(120),
                        child: GestureDetector(
                          excludeFromSemantics: true,
                          behavior: HitTestBehavior.opaque,
                          onTapUp: (details) {
                            OrganStructure? nearest;
                            var distance = 22.0;
                            for (final target in targets) {
                              final anchor = _illustratedAnchors[target.id]!;
                              final center = Offset(
                                left + anchor.dx * scale,
                                top + anchor.dy * scale,
                              );
                              final candidate =
                                  (details.localPosition - center).distance;
                              if (candidate < distance) {
                                distance = candidate;
                                nearest = target;
                              }
                            }
                            if (nearest != null) widget.onSelected(nearest);
                          },
                          child: SizedBox(
                            width: box.maxWidth,
                            height: box.maxHeight,
                            child: Stack(
                              children: [
                                Positioned(
                                  left: left,
                                  top: top,
                                  width: 300 * scale,
                                  height: 450 * scale,
                                  child: Image.asset(
                                    'assets/quizipedia/anatomy-orientation-display.webp',
                                    fit: BoxFit.contain,
                                    semanticLabel: ru
                                        ? 'Схема органов: вид спереди'
                                        : 'Anterior organ overview',
                                  ),
                                ),
                                for (var i = 0; i < targets.length; i++)
                                  Positioned(
                                    left:
                                        left +
                                        _illustratedAnchors[targets[i].id]!.dx *
                                            scale -
                                        11 * scale,
                                    top:
                                        top +
                                        _illustratedAnchors[targets[i].id]!.dy *
                                            scale -
                                        11 * scale,
                                    width: 22 * scale,
                                    height: 22 * scale,
                                    child: Listener(
                                      behavior: HitTestBehavior.opaque,
                                      child: Container(
                                        key: Key(
                                          'organ-map-target-${targets[i].id}',
                                        ),
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .primaryContainer,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .primary,
                                          ),
                                        ),
                                        child: Text(
                                          '${i + 1}',
                                          style: TextStyle(
                                            fontSize: 12 * scale,
                                            fontWeight: FontWeight.bold,
                                            color: Theme.of(context)
                                                .colorScheme
                                                .onPrimaryContainer,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (var i = 0; i < targets.length; i++)
              TextButton(
                key: Key('organ-map-card-${targets[i].id}'),
                onPressed: () => widget.onSelected(targets[i]),
                child: Text('${i + 1}. ${widget.name(targets[i])}'),
              ),
          ],
        ),
        if (widget.selected != null &&
            !_illustratedAnchors.containsKey(widget.selected!.id))
          Text(
            ru
                ? '${widget.name(widget.selected!)}: расположение и функции — в карточке ниже.'
                : '${widget.name(widget.selected!)}: see the card for location and function.',
          ),
      ],
    );
  }
}

// Retained as a fallback sketch for future non-illustrated anatomy views.
// ignore: unused_element
class _BodyPainter extends CustomPainter {
  const _BodyPainter(this.organs, this.selected, this.colors);
  final List<OrganStructure> organs;
  final String? selected;
  final ColorScheme colors;
  @override
  void paint(Canvas canvas, Size size) {
    final body = Paint()..color = colors.surfaceContainerHighest;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(106, 10, 88, 105),
        const Radius.circular(44),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(72, 95, 156, 280),
        const Radius.circular(62),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(46, 115, 35, 210),
        const Radius.circular(20),
      ),
      body,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(219, 115, 35, 210),
        const Radius.circular(20),
      ),
      body,
    );
    final shapes = <String, Path>{};
    Path p() => Path();
    shapes['brain'] = p()..addOval(const Rect.fromLTWH(119, 32, 62, 43));
    shapes['heart'] = p()
      ..moveTo(164, 166)
      ..cubicTo(124, 128, 123, 190, 169, 211)
      ..cubicTo(215, 190, 214, 128, 174, 166)
      ..close();
    shapes['lungs'] = p()
      ..addOval(const Rect.fromLTWH(92, 128, 56, 92))
      ..addOval(const Rect.fromLTWH(153, 128, 56, 92));
    shapes['liver'] = p()
      ..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(82, 225, 105, 43),
          const Radius.circular(18),
        ),
      );
    shapes['stomach'] = p()..addOval(const Rect.fromLTWH(165, 247, 42, 65));
    shapes['kidneys'] = p()
      ..addOval(const Rect.fromLTWH(103, 278, 32, 48))
      ..addOval(const Rect.fromLTWH(165, 278, 32, 48));
    shapes['bladder'] = p()..addOval(const Rect.fromLTWH(130, 340, 40, 31));
    // Enlarged teaching silhouettes; the written card gives the actual position.
    shapes['thyroid'] = p()
      ..moveTo(150, 102)
      ..cubicTo(133, 87, 128, 104, 139, 118)
      ..lineTo(148, 111)
      ..lineTo(152, 111)
      ..lineTo(161, 118)
      ..cubicTo(172, 104, 167, 87, 150, 102)
      ..close();
    shapes['parathyroids'] = p()
      ..addOval(const Rect.fromLTWH(137, 100, 5, 5))
      ..addOval(const Rect.fromLTWH(137, 110, 5, 5))
      ..addOval(const Rect.fromLTWH(158, 100, 5, 5))
      ..addOval(const Rect.fromLTWH(158, 110, 5, 5));
    shapes['adrenals'] = p()
      ..moveTo(103, 274)
      ..lineTo(120, 263)
      ..lineTo(136, 274)
      ..close()
      ..moveTo(164, 274)
      ..quadraticBezierTo(180, 258, 197, 274)
      ..close();
    shapes['pancreas'] = p()
      ..moveTo(121, 265)
      ..cubicTo(136, 255, 164, 266, 187, 260)
      ..quadraticBezierTo(204, 269, 186, 276)
      ..cubicTo(164, 279, 141, 270, 124, 279)
      ..quadraticBezierTo(115, 273, 121, 265)
      ..close();
    shapes['thymus'] = p()
      ..addOval(const Rect.fromLTWH(140, 124, 10, 29))
      ..addOval(const Rect.fromLTWH(151, 124, 10, 29));

    const depth = {
      'pancreas': -1,
      'adrenals': -1,
      'thyroid': 7,
      'parathyroids': 8,
      'thymus': 1,
      'lungs': 0,
      'kidneys': 1,
      'liver': 2,
      'stomach': 3,
      'bladder': 4,
      'brain': 5,
      'heart': 6,
    };
    final ordered = [...organs]
      ..sort(
        (a, b) => (a.id == selected ? 100 : depth[a.id] ?? 10).compareTo(
          b.id == selected ? 100 : depth[b.id] ?? 10,
        ),
      );
    const organColors = {
      'heart': Color(0xffda7978),
      'lungs': Color(0xff82b9d4),
      'brain': Color(0xffd4a6c5),
      'liver': Color(0xffb78468),
      'stomach': Color(0xffe5b88a),
      'kidneys': Color(0xffac91c8),
      'bladder': Color(0xffddc578),
    };
    for (final organ in ordered) {
      if (organ.region == 'distributed') continue;
      final key = organ.id.toLowerCase();
      Path? shape;
      for (final entry in shapes.entries) {
        if (key.contains(entry.key) ||
            (entry.key == 'lungs' &&
                (key.contains('lung') || key.contains('bronch')))) {
          shape = entry.value;
          break;
        }
      }
      if (shape == null && organ.id != selected) continue;
      shape ??= _regionMark(organ.region);
      final paint = Paint()
        ..color = organ.id == selected
            ? colors.primary
            : organColors[organ.id] ?? _colorFor(organ.kind, colors);
      canvas.drawPath(shape, paint);
      canvas.drawPath(
        shape,
        Paint()
          ..color = colors.onSurface.withValues(alpha: .55)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  Path _regionMark(String region) {
    if (region == 'distributed') {
      return Path()..addRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(78, 102, 144, 267),
          const Radius.circular(58),
        ),
      );
    }
    final y = switch (region) {
      'head' => 60,
      'neck' => 105,
      'thorax' => 170,
      'abdomen' => 255,
      'pelvis' => 345,
      _ => 395,
    };
    return Path()
      ..addOval(Rect.fromCircle(center: Offset(150, y.toDouble()), radius: 7));
  }

  Color _colorFor(String kind, ColorScheme c) => switch (kind) {
    'endocrine_gland' => c.tertiary,
    'exocrine_gland' => c.secondary,
    'mixed_gland' => c.primaryContainer,
    'gland_group' => c.tertiaryContainer,
    _ => c.secondaryContainer,
  };
  @override
  bool shouldRepaint(covariant _BodyPainter old) =>
      old.organs != organs || old.selected != selected || old.colors != colors;
}

class _Detail extends StatelessWidget {
  const _Detail({
    required this.item,
    required this.atlas,
    required this.russian,
  });
  final OrganStructure item;
  final OrganAtlas atlas;
  final bool russian;
  String v(String en, String ru) => russian ? russianLearningText(ru) : en;
  @override
  Widget build(BuildContext context) => Card(
    key: const Key('organ-detail'),
    margin: const EdgeInsets.only(top: 16),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            v(item.nameEn, item.nameRu),
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (item.nameLa != null)
            ExpansionTile(
              key: const Key('organ-latin-name'),
              tilePadding: EdgeInsets.zero,
              title: Text(v('Latin name', 'Латинское название')),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(item.nameLa!),
                ),
              ],
            ),
          if (item.boneCount != null)
            Text(
              v(
                'Bones in group: ${item.boneCount}',
                'Костей в группе: ${item.boneCount}',
              ),
            ),
          Text(
            '${v('Position', 'Положение')}: ${v(item.positionEn, item.positionRu)}',
          ),
          Text(
            '${v('Function', 'Функция')}: ${v(item.functionEn, item.functionRu)}',
          ),
          if (item.secretionsEn.isNotEmpty)
            Text(
              '${v('Secretions', 'Секреции')}: ${(russian ? item.secretionsRu : item.secretionsEn).join(', ')}',
            ),
          for (final fact in item.facts)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('• ${v(fact.textEn, fact.textRu)}'),
            ),
          if (v(item.noteEn, item.noteRu).isNotEmpty)
            Text('${v('Note', 'Примечание')}: ${v(item.noteEn, item.noteRu)}'),
          for (final id in item.sourceIds)
            TextButton.icon(
              onPressed: () => launchUrl(
                Uri.parse(atlas.source(id).url),
                mode: LaunchMode.externalApplication,
              ),
              icon: const Icon(Icons.open_in_new),
              label: Text(
                '${v('Source', 'Источник')}: ${learningSourceTitle(atlas.source(id).title, russian: russian)}',
              ),
            ),
        ],
      ),
    ),
  );
}
