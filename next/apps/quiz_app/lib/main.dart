// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_app/l10n/app_localizations.dart';

void main() => runApp(const ProviderScope(child: QuizApp()));

enum AnswerKind { singleChoice, multipleChoice, normalizedText }

class Revision {
  const Revision(this.number, this.sha256);
  final int number;
  final String sha256;
  factory Revision.fromJson(Map<String, dynamic> json) {
    _closed(json, {'number', 'sha256'});
    if (json['number'] is! int ||
        (json['number'] as int) < 1 ||
        json['sha256'] is! String ||
        !RegExp(r'^[0-9a-f]{64}$').hasMatch(json['sha256'] as String)) {
      throw const FormatException('revision');
    }
    return Revision(json['number'] as int, json['sha256'] as String);
  }
}

class PublicOption {
  const PublicOption({required this.id, required this.text});
  final String id;
  final String text;
  factory PublicOption.fromJson(Map<String, dynamic> json) {
    _closed(json, {'option_id', 'text', 'media'});
    if (json['option_id'] is! String ||
        !_validId(json['option_id'] as String) ||
        json['text'] is! String ||
        (json['text'] as String).isEmpty) {
      throw const FormatException('option');
    }
    if (json['media'] != null) Media.fromJson(_map(json['media']));
    return PublicOption(
      id: json['option_id'] as String,
      text: json['text'] as String,
    );
  }
}

class Source {
  const Source();
  factory Source.fromJson(Map<String, dynamic> json) {
    _closed(json, {'uri', 'title'});
    if (json['uri'] is! String ||
        (json['uri'] as String).isEmpty ||
        (json['title'] != null && json['title'] is! String))
      throw const FormatException('source');
    return const Source();
  }
}

class Media {
  const Media();
  factory Media.fromJson(Map<String, dynamic> json) {
    _closed(json, {'uri', 'kind', 'alt'});
    if (json['uri'] is! String ||
        (json['uri'] as String).isEmpty ||
        (json['kind'] != null && json['kind'] is! String) ||
        (json['alt'] != null && json['alt'] is! String))
      throw const FormatException('media');
    return const Media();
  }
}

class PublicQuestion {
  const PublicQuestion({
    required this.quizId,
    required this.id,
    required this.revision,
    required this.stem,
    required this.options,
    required this.kind,
  });
  final String quizId;
  final String id;
  final Revision revision;
  final String stem;
  final List<PublicOption> options;
  final AnswerKind kind;
  factory PublicQuestion.fromJson(Map<String, dynamic> json) {
    _closed(json, {
      'quiz_id',
      'question_id',
      'revision',
      'stem',
      'options',
      'difficulty',
      'source',
      'media',
      'answer_kind',
    });
    final options = json['options'];
    final kind = switch (json['answer_kind']) {
      'single_choice' => AnswerKind.singleChoice,
      'multiple_choice' => AnswerKind.multipleChoice,
      'normalized_text' => AnswerKind.normalizedText,
      _ => throw const FormatException('answer_kind'),
    };
    const difficulties = {'unknown', 'easy', 'medium', 'hard'};
    if (json['quiz_id'] is! String ||
        !_validId(json['quiz_id'] as String) ||
        json['question_id'] is! String ||
        !_validId(json['question_id'] as String) ||
        json['stem'] is! String ||
        (json['stem'] as String).isEmpty ||
        !difficulties.contains(json['difficulty']) ||
        options is! List ||
        options.length < 4 ||
        options.length > 6) {
      throw const FormatException('public question');
    }
    final media = json['media'];
    if (media != null && media is! List) throw const FormatException('media');
    Source.fromJson(_map(json['source']));
    if (media != null) {
      for (final item in media) {
        Media.fromJson(_map(item));
      }
    }
    final parsedOptions = options
        .map((e) => PublicOption.fromJson(_map(e)))
        .toList(growable: false);
    if (parsedOptions.map((option) => option.id).toSet().length !=
        parsedOptions.length) {
      throw const FormatException('duplicate option');
    }
    return PublicQuestion(
      quizId: json['quiz_id'] as String,
      id: json['question_id'] as String,
      revision: Revision.fromJson(_map(json['revision'])),
      stem: json['stem'] as String,
      options: parsedOptions,
      kind: kind,
    );
  }
}

class Reveal {
  const Reveal({required this.answer, required this.explanation});
  final String answer;
  final String explanation;
  factory Reveal.fromJson(Map<String, dynamic> json) {
    _closed(json, {
      'quiz_id',
      'question_id',
      'question_revision',
      'correct_answer',
      'explanation',
    });
    if (json['quiz_id'] is! String ||
        !_validId(json['quiz_id'] as String) ||
        json['question_id'] is! String ||
        !_validId(json['question_id'] as String) ||
        json['explanation'] is! String ||
        (json['explanation'] as String).isEmpty) {
      throw const FormatException('reveal');
    }
    Revision.fromJson(_map(json['question_revision']));
    final answer = _map(json['correct_answer']);
    _closed(answer, {'option_id', 'option_ids', 'text'});
    final keys = answer.keys.toSet();
    final single =
        keys.length == 2 &&
        keys.containsAll({'option_id', 'text'}) &&
        answer['option_id'] is String &&
        _validId(answer['option_id'] as String);
    final optionIds = answer['option_ids'];
    final multiple =
        keys.length == 2 &&
        keys.containsAll({'option_ids', 'text'}) &&
        optionIds is List &&
        optionIds.isNotEmpty &&
        optionIds.every((id) => id is String && _validId(id)) &&
        optionIds.toSet().length == optionIds.length;
    final text = keys.length == 1 && keys.contains('text');
    if (answer['text'] is! String ||
        (answer['text'] as String).isEmpty ||
        (!single && !multiple && !text)) {
      throw const FormatException('reveal');
    }
    return Reveal(
      answer: answer['text'] as String,
      explanation: json['explanation'] as String,
    );
  }
}

class ApiFailure {
  const ApiFailure({
    required this.code,
    required this.message,
    required this.retryable,
    required this.details,
  });
  final String code;
  final String message;
  final bool retryable;
  final Map<String, String> details;
  factory ApiFailure.fromJson(Map<String, dynamic> json) {
    _closed(json, {'code', 'message', 'retryable', 'details'});
    const codes = {
      'deadline_exceeded',
      'stale_revision',
      'stale_round',
      'forbidden',
      'validation_failed',
      'idempotency_conflict',
    };
    if (!codes.contains(json['code']) ||
        json['message'] is! String ||
        json['retryable'] is! bool ||
        json['details'] is! Map ||
        (json['details'] as Map).entries.any(
          (entry) => entry.key is! String || entry.value is! String,
        ))
      throw const FormatException('error envelope');
    final details = Map<String, String>.from(json['details'] as Map);
    return ApiFailure(
      code: json['code'] as String,
      message: json['message'] as String,
      retryable: json['retryable'] as bool,
      details: details,
    );
  }
}

void _closed(Map<String, dynamic> value, Set<String> allowed) {
  if (value.keys.any((key) => !allowed.contains(key))) {
    throw const FormatException('unknown or private field');
  }
}

Map<String, dynamic> _map(Object? value) {
  if (value is! Map<String, dynamic>) {
    throw const FormatException('object required');
  }
  return value;
}

bool _validId(String value) =>
    RegExp(r'^[a-z][a-z0-9-]{2,63}$').hasMatch(value);

class QuizApiClient {
  QuizApiClient({
    required Uri baseUri,
    Duration timeout = const Duration(seconds: 10),
  }) : _dio = Dio(
         BaseOptions(
           baseUrl: _validBaseUri(baseUri).toString(),
           connectTimeout: timeout,
           receiveTimeout: timeout,
         ),
       );
  final Dio _dio;
  Dio get dio => _dio;
  static Uri _validBaseUri(Uri uri) {
    if (!uri.hasScheme ||
        !uri.hasAuthority ||
        !(uri.scheme == 'https' || uri.scheme == 'http'))
      throw ArgumentError.value(
        uri,
        'baseUri',
        'must be an absolute HTTP(S) URI',
      );
    return uri;
  }
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);
final localeProvider = NotifierProvider<LocaleController, Locale?>(
  LocaleController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.system;
  void select(ThemeMode value) => state = value;
}

class LocaleController extends Notifier<Locale?> {
  @override
  Locale? build() => null;
  void select(Locale? value) => state = value;
}

class QuizApp extends ConsumerStatefulWidget {
  const QuizApp({super.key, this.initialLocation = '/'});
  final String initialLocation;

  @override
  ConsumerState<QuizApp> createState() => _QuizAppState();
}

class _QuizAppState extends ConsumerState<QuizApp> {
  late final GoRouter _router = createRouter(
    initialLocation: widget.initialLocation,
  );

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context)!.catalogTitle,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: _router,
    );
  }
}

ThemeData _theme(Brightness brightness) => ThemeData(
  useMaterial3: true,
  brightness: brightness,
  colorSchemeSeed: const Color(0xff006b5f),
);

GoRouter createRouter({String initialLocation = '/'}) => GoRouter(
  initialLocation: initialLocation,
  routes: [
    GoRoute(path: '/', builder: (_, _) => const CatalogPage()),
    GoRoute(path: '/gallery', builder: (_, _) => const GalleryPage()),
    GoRoute(
      path: '/join/:inviteToken',
      builder: (_, state) =>
          JoinPage(token: state.pathParameters['inviteToken']!),
    ),
  ],
);

class AppScaffold extends ConsumerWidget {
  const AppScaffold({super.key, required this.title, required this.body});
  final String title;
  final Widget body;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
    appBar: AppBar(
      title: Text(title),
      actions: [
        IconButton(
          tooltip: AppLocalizations.of(context)!.english,
          onPressed: () =>
              ref.read(localeProvider.notifier).select(const Locale('en')),
          icon: const Icon(Icons.language),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context)!.russian,
          onPressed: () =>
              ref.read(localeProvider.notifier).select(const Locale('ru')),
          icon: const Icon(Icons.translate),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context)!.lightTheme,
          onPressed: () =>
              ref.read(themeModeProvider.notifier).select(ThemeMode.light),
          icon: const Icon(Icons.light_mode),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context)!.darkTheme,
          onPressed: () =>
              ref.read(themeModeProvider.notifier).select(ThemeMode.dark),
          icon: const Icon(Icons.dark_mode),
        ),
        IconButton(
          tooltip: AppLocalizations.of(context)!.systemTheme,
          onPressed: () =>
              ref.read(themeModeProvider.notifier).select(ThemeMode.system),
          icon: const Icon(Icons.brightness_auto),
        ),
      ],
    ),
    body: SafeArea(child: body),
  );
}

class CatalogPage extends StatelessWidget {
  const CatalogPage({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      title: l10n.catalogTitle,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            PackTile(title: l10n.galleryTitle, subtitle: l10n.practiceUnranked),
            FilledButton(
              onPressed: () => context.push('/gallery'),
              child: Text(l10n.openGallery),
            ),
          ],
        ),
      ),
    );
  }
}

class JoinPage extends StatelessWidget {
  const JoinPage({super.key, required this.token});
  final String token;
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) context.go('/');
      },
      child: AppScaffold(
        title: l10n.joinTitle,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '${l10n.inviteToken(token)}\n${l10n.joinAdmissionOnly}',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

class GalleryPage extends StatefulWidget {
  const GalleryPage({super.key});
  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  late final List<PublicQuestion> questions = fixtures;
  @override
  Widget build(BuildContext context) => AppScaffold(
    title: AppLocalizations.of(context)!.galleryTitle,
    body: ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final question in questions)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: QuestionCard(question: question, onAnswer: (_) {}),
          ),
      ],
    ),
  );
}

class PackTile extends StatelessWidget {
  const PackTile({super.key, required this.title, required this.subtitle});
  final String title;
  final String subtitle;
  @override
  Widget build(BuildContext context) => Semantics(
    label: title,
    child: Card(
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        leading: const Icon(Icons.quiz),
      ),
    ),
  );
}

class QuestionCard extends StatefulWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.onAnswer,
    this.submitting = false,
    this.reveal,
  });
  final PublicQuestion question;
  final ValueChanged<Object> onAnswer;
  final bool submitting;
  final Reveal? reveal;
  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  String? single;
  final multiple = <String>{};
  final text = TextEditingController();
  @override
  void dispose() {
    text.dispose();
    super.dispose();
  }

  bool get _disabled => widget.submitting || widget.reveal != null;

  void _selectSingle(String id) {
    if (_disabled) return;
    setState(() => single = id);
    widget.onAnswer(id);
  }

  void _toggleMultiple(String id) {
    if (_disabled) return;
    setState(() {
      multiple.contains(id) ? multiple.remove(id) : multiple.add(id);
    });
    widget.onAnswer(multiple.toSet());
  }

  void _submitText() {
    if (_disabled) return;
    final answer = _normalize(text.text);
    if (answer.isNotEmpty) widget.onAnswer(answer);
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _disabled;
    final choices = widget.question.options
        .map(
          (option) => switch (widget.question.kind) {
            AnswerKind.singleChoice => _ChoiceControl(
              label: option.text,
              stableId: option.id,
              selected: single == option.id,
              disabled: disabled,
              onActivate: () => _selectSingle(option.id),
              child: RadioListTile<String>(
                value: option.id,
                groupValue: single,
                onChanged: disabled ? null : (id) => _selectSingle(id!),
                title: Text(option.text),
              ),
            ),
            AnswerKind.multipleChoice => _ChoiceControl(
              label: option.text,
              stableId: option.id,
              selected: multiple.contains(option.id),
              disabled: disabled,
              onActivate: () => _toggleMultiple(option.id),
              child: CheckboxListTile(
                value: multiple.contains(option.id),
                onChanged: disabled ? null : (_) => _toggleMultiple(option.id),
                title: Text(option.text),
              ),
            ),
            AnswerKind.normalizedText => const SizedBox.shrink(),
          },
        )
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.question.stem,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (widget.question.kind == AnswerKind.normalizedText)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: text,
                    enabled: !disabled,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() {}),
                    onSubmitted: disabled ? null : (_) => _submitText(),
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.yourAnswer,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: disabled || _normalize(text.text).isEmpty
                        ? null
                        : _submitText,
                    child: Text(AppLocalizations.of(context)!.submitAnswer),
                  ),
                ],
              )
            else
              ...choices,
            if (widget.reveal != null) ExplanationPanel(reveal: widget.reveal!),
          ],
        ),
      ),
    );
  }
}

class _ChoiceControl extends StatefulWidget {
  const _ChoiceControl({
    required this.label,
    required this.stableId,
    required this.selected,
    required this.disabled,
    required this.onActivate,
    required this.child,
  });

  final String label;
  final String stableId;
  final bool selected;
  final bool disabled;
  final VoidCallback onActivate;
  final Widget child;

  @override
  State<_ChoiceControl> createState() => _ChoiceControlState();
}

class _ChoiceControlState extends State<_ChoiceControl> {
  bool _focused = false;

  KeyEventResult _handleKey(FocusNode _, KeyEvent event) {
    if (widget.disabled || event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      widget.onActivate();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    excludeSemantics: true,
    label: widget.label,
    value: widget.stableId,
    button: true,
    selected: widget.selected,
    enabled: !widget.disabled,
    onTap: widget.disabled ? null : widget.onActivate,
    child: Focus(
      canRequestFocus: !widget.disabled,
      skipTraversal: widget.disabled,
      descendantsAreFocusable: false,
      onFocusChange: (focused) => setState(() => _focused = focused),
      onKeyEvent: _handleKey,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: _focused
              ? Border.all(color: Theme.of(context).colorScheme.primary)
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: widget.child,
      ),
    ),
  );
}

String _normalize(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

class ExplanationPanel extends StatelessWidget {
  const ExplanationPanel({super.key, required this.reveal});
  final Reveal reveal;
  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    child: Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.answer(reveal.answer),
            style: Theme.of(context).textTheme.titleMedium,
          ),
          Text(reveal.explanation),
        ],
      ),
    ),
  );
}

final fixtures = <PublicQuestion>[
  PublicQuestion(
    quizId: 'everyday-science',
    id: 'q-sun',
    revision: Revision(
      1,
      '2222222222222222222222222222222222222222222222222222222222222222',
    ),
    stem: 'Which option is our star?',
    kind: AnswerKind.singleChoice,
    options: const [
      PublicOption(id: 'opt-sun', text: 'The Sun'),
      PublicOption(id: 'opt-moon', text: 'The Moon'),
      PublicOption(id: 'opt-mars', text: 'Mars'),
      PublicOption(id: 'opt-venus', text: 'Venus'),
    ],
  ),
  PublicQuestion(
    quizId: 'everyday-science',
    id: 'q-water',
    revision: Revision(
      2,
      '3333333333333333333333333333333333333333333333333333333333333333',
    ),
    stem: 'Select states of water.',
    kind: AnswerKind.multipleChoice,
    options: const [
      PublicOption(id: 'opt-solid', text: 'Solid'),
      PublicOption(id: 'opt-liquid', text: 'Liquid'),
      PublicOption(id: 'opt-gas', text: 'Gas'),
      PublicOption(id: 'opt-plasma', text: 'Plasma'),
      PublicOption(id: 'opt-light', text: 'Light'),
    ],
  ),
  PublicQuestion(
    quizId: 'everyday-science',
    id: 'q-planet',
    revision: Revision(
      1,
      '4444444444444444444444444444444444444444444444444444444444444444',
    ),
    stem: 'Name the red planet.',
    kind: AnswerKind.normalizedText,
    options: const [
      PublicOption(id: 'opt-red', text: 'Red'),
      PublicOption(id: 'opt-blue', text: 'Blue'),
      PublicOption(id: 'opt-green', text: 'Green'),
      PublicOption(id: 'opt-white', text: 'White'),
      PublicOption(id: 'opt-black', text: 'Black'),
      PublicOption(id: 'opt-gold', text: 'Gold'),
    ],
  ),
];
