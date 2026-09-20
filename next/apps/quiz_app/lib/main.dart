// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_app/l10n/app_localizations.dart';

part 'api_models.dart';
part 'api_repository.dart';
part 'journey.dart';
part 'journey_pages.dart';

void main() => runApp(const ProviderScope(child: QuizApp()));

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
    GoRoute(path: '/history', builder: (_, _) => const HistoryPage()),
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
