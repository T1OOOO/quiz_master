import 'dart:math';

import 'package:flutter/material.dart';

import 'quizipedia.dart';
import 'waterways_models.dart';

String _t(BuildContext c, String en, String ru) =>
    Localizations.localeOf(c).languageCode == 'ru' ? ru : en;
String _name(BuildContext c, WaterShape w) =>
    Localizations.localeOf(c).languageCode == 'ru' ? w.nameRu : w.nameEn;

Future<String?> pickWater(BuildContext context, WaterAtlas atlas) =>
    showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _WaterPicker(atlas: atlas),
    );

class _WaterPicker extends StatefulWidget {
  const _WaterPicker({required this.atlas});
  final WaterAtlas atlas;
  @override
  State<_WaterPicker> createState() => _WaterPickerState();
}

class _WaterPickerState extends State<_WaterPicker> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final rows = widget.atlas.features
        .where(
          (w) => '${w.nameRu} ${w.nameEn}'.toLowerCase().contains(
            query.toLowerCase().trim(),
          ),
        )
        .toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * .75,
        child: Column(
          children: [
            ListTile(
              title: Text(_t(context, 'Water bodies · 63', 'Водоёмы · 63')),
              trailing: IconButton(
                tooltip: _t(context, 'Close', 'Закрыть'),
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const Key('water-search'),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  labelText: _t(
                    context,
                    'Find a river, lake or sea',
                    'Найти реку, озеро или море',
                  ),
                ),
                onChanged: (v) => setState(() => query = v),
              ),
            ),
            Expanded(
              child: rows.isEmpty
                  ? Center(
                      child: Text(
                        _t(context, 'No matches', 'Ничего не найдено'),
                      ),
                    )
                  : ListView.builder(
                      itemCount: rows.length,
                      itemBuilder: (context, i) => ListTile(
                        title: Text(_name(context, rows[i])),
                        subtitle: Text(
                          _t(
                            context,
                            'Show on map; zoom stays manual',
                            'Выбрать на карте · масштаб вручную',
                          ),
                        ),
                        onTap: () => Navigator.pop(context, rows[i].id),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Local recognition practice; it does not submit scores to ranked APIs.
class WaterPracticePage extends StatefulWidget {
  const WaterPracticePage({
    super.key,
    required this.catalog,
    required this.atlas,
  });
  final QuizipediaCatalog catalog;
  final WaterAtlas atlas;
  @override
  State<WaterPracticePage> createState() => _WaterPracticePageState();
}

class _WaterPracticePageState extends State<WaterPracticePage> {
  final camera = TransformationController();
  final scroll = ScrollController();
  final random = Random();
  late final List<WaterShape> questions = [...widget.atlas.features]
    ..shuffle(random);
  late List<WaterShape> choices = _choices();
  int index = 0, score = 0;
  String? choice, compare;
  bool checked = false;
  WaterShape get question => questions[index];
  List<WaterShape> _choices() {
    final other =
        widget.atlas.features.where((w) => w.id != question.id).toList()
          ..shuffle(random);
    return [question, ...other.take(5)]..shuffle(random);
  }

  @override
  void dispose() {
    scroll.dispose();
    camera.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_t(context, 'Water bodies', 'Водоёмы'))),
    body: LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        controller: scroll,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                '${index + 1}/${questions.length} · ${_t(context, 'Correct', 'Верно')}: $score\n${_t(context, 'Name the highlighted river, lake or sea', 'Как называется выделенная река, озеро или море?')}',
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: max(240, min(420, constraints.maxHeight * .48)),
              child: QuizipediaWorldMap(
                features: widget.catalog.countries,
                controller: camera,
                onSelect: (_) {},
                selectionEnabled: false,
                showSelectionLabel: false,
                showLabels: false,
                waters: widget.atlas.features,
                selectedWater: compare ?? question.id,
                showWaterLabels: checked,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    _t(
                      context,
                      'Use + or the focus button to inspect the highlighted shape.',
                      'Используйте + или кнопку фокуса, чтобы рассмотреть выделенный объект.',
                    ),
                  ),
                  const SizedBox(height: 8),
                  for (final w in choices)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton(
                        key: ValueKey('water-answer-${w.id}'),
                        style: OutlinedButton.styleFrom(
                          backgroundColor: checked && w.id == question.id
                              ? Theme.of(context).colorScheme.primaryContainer
                              : choice == w.id
                              ? Theme.of(context).colorScheme.secondaryContainer
                              : null,
                        ),
                        onPressed: checked
                            ? null
                            : () => setState(() => choice = w.id),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Text(
                            '${checked && w.id == question.id
                                ? '✓ '
                                : checked && w.id == choice
                                ? '✗ '
                                : choice == w.id
                                ? '● '
                                : ''}${_name(context, w)}',
                          ),
                        ),
                      ),
                    ),
                  if (!checked)
                    FilledButton(
                      key: const Key('water-check'),
                      onPressed: choice == null
                          ? null
                          : () => setState(() {
                              checked = true;
                              if (choice == question.id) score++;
                            }),
                      child: Text(_t(context, 'Check', 'Проверить')),
                    ),
                  if (checked) ...[
                    Text(
                      '${_t(context, 'Correct answer', 'Правильный ответ')}: ${_name(context, question)}',
                      key: const Key('water-feedback'),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      _t(
                        context,
                        'Compare every option on the map; move and zoom manually.',
                        'Сравните каждый вариант на карте; перемещайте и увеличивайте вручную.',
                      ),
                    ),
                    Wrap(
                      spacing: 8,
                      children: choices
                          .map(
                            (w) => ActionChip(
                              label: Text(_name(context, w)),
                              onPressed: () => setState(() => compare = w.id),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 8),
                    FilledButton(
                      key: const Key('water-next'),
                      onPressed: () => setState(() {
                        if (index == questions.length - 1) {
                          index = 0;
                          score = 0;
                          questions.shuffle(random);
                        } else {
                          index++;
                        }
                        checked = false;
                        choice = null;
                        compare = null;
                        choices = _choices();
                        scroll.jumpTo(0);
                      }),
                      child: Text(
                        index == questions.length - 1
                            ? _t(context, 'New round', 'Новый круг')
                            : _t(context, 'Next', 'Дальше'),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Text(
                    _t(
                      context,
                      'Selected objects from Natural Earth, scale 1:110m. Small rivers and lakes are not included.',
                      'Избранные объекты Natural Earth, масштаб 1:110 млн. Мелкие реки и озёра не включены.',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
