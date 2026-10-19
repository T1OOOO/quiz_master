// ignore_for_file: curly_braces_in_flow_control_structures, deprecated_member_use

import 'dart:async';
import 'dart:ui' as ui;
import 'dart:convert';
import 'dart:ui' show PointerDeviceKind;
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_app/l10n/app_localizations.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'quizipedia.dart';
import 'question_articles.dart';

part 'api_models.dart';
part 'api_repository.dart';
part 'journey.dart';
part 'journey_pages.dart';
part 'discovery.dart';
part 'source_style.dart';
part 'study_pages.dart';
part 'feedback.dart';
part 'feedback_admin.dart';

void main() => runApp(
  const ProviderScope(
    child: QuizApp(initialLocation: '/quizipedia', defaultLocale: Locale('ru')),
  ),
);

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
  const QuizApp({
    super.key,
    this.initialLocation = '/',
    this.defaultLocale = const Locale('ru'),
  });
  final String initialLocation;
  final Locale? defaultLocale;

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
      locale: ref.watch(localeProvider) ?? widget.defaultLocale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      routerConfig: _router,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        dragDevices: {
          ...const MaterialScrollBehavior().dragDevices,
          PointerDeviceKind.mouse,
        },
      ),
    );
  }
}

ThemeData _theme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final colors = ColorScheme.fromSeed(
    seedColor: const Color(0xff477ab5),
    brightness: brightness,
    surface: dark ? const Color(0xff111923) : const Color(0xfff5f7fb),
  );
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colors,
    scaffoldBackgroundColor: colors.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: colors.surfaceContainerLow,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colors.outlineVariant.withValues(alpha: .5)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colors.surfaceContainerLow,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(48, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

GoRouter createRouter({String initialLocation = '/'}) {
  final contentNavigator = GlobalKey<NavigatorState>();
  return GoRouter(
    initialLocation: initialLocation,
    routes: [
      // Keep global controls below the navigator's already-owned overlay.
      ShellRoute(
        navigatorKey: contentNavigator,
        builder: (context, state, child) => _MainNavigation(
          path: state.uri.path,
          resetPages: () =>
              contentNavigator.currentState?.popUntil((route) => route.isFirst),
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/quizipedia',
            builder: (context, _) =>
                QuizipediaPage(onExit: () => context.go('/library')),
          ),
          GoRoute(path: '/study', builder: (_, _) => const StudyLibraryPage()),
          GoRoute(
            path: '/study/:moduleId/practice',
            builder: (_, state) =>
                StudyPracticePage(moduleId: state.pathParameters['moduleId']!),
          ),
          GoRoute(
            path: '/study/:moduleId',
            builder: (_, state) =>
                StudyArticlePage(moduleId: state.pathParameters['moduleId']!),
          ),
          GoRoute(
            path: '/library',
            builder: (_, state) => DiscoveryPage(
              folder: state.uri.queryParameters['folder'] ?? '',
              query: state.uri.queryParameters['q'] ?? '',
              difficulty: difficultyBandFromWire(
                state.uri.queryParameters['difficulty'],
              ),
            ),
          ),
          GoRoute(path: '/', builder: (_, _) => const CatalogPage()),
          GoRoute(
            path: '/quiz/:quizId',
            builder: (_, state) => CatalogPage(
              key: ValueKey(state.uri.toString()),
              quizId: state.pathParameters['quizId']!,
              round: state.uri.queryParameters.containsKey('round')
                  ? int.tryParse(state.uri.queryParameters['round']!) ?? -1
                  : null,
              difficulty: difficultyBandFromWire(
                state.uri.queryParameters['difficulty'],
              ),
            ),
          ),
          GoRoute(path: '/gallery', builder: (_, _) => const GalleryPage()),
          GoRoute(path: '/history', builder: (_, _) => const HistoryPage()),
          GoRoute(
            path: '/feedback',
            builder: (_, _) => const FeedbackAdminPage(),
          ),
          GoRoute(
            path: '/join/:inviteToken',
            builder: (_, state) =>
                JoinPage(token: state.pathParameters['inviteToken']!),
          ),
        ],
      ),
    ],
  );
}

class _MainNavigation extends StatelessWidget {
  const _MainNavigation({
    required this.path,
    required this.child,
    required this.resetPages,
  });
  final VoidCallback resetPages;
  final String path;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final hidden = path == '/feedback' || path.startsWith('/join/');
    return Scaffold(
      body: _FeedbackOverlay(router: GoRouter.of(context), child: child),
      bottomNavigationBar: hidden
          ? null
          : NavigationBar(
              height: 64,
              selectedIndex: path.startsWith('/quizipedia')
                  ? 0
                  : path.startsWith('/study')
                  ? 2
                  : 1,
              onDestinationSelected: (index) {
                resetPages();
                final target = const [
                  '/quizipedia',
                  '/library',
                  '/study',
                ][index];
                context.go(target);
              },
              destinations: [
                NavigationDestination(
                  icon: const Icon(Icons.public),
                  label: ru ? 'Квизипедия' : 'Quizipedia',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.quiz_outlined),
                  label: ru ? 'Квизы' : 'Quizzes',
                ),
                NavigationDestination(
                  icon: const Icon(Icons.menu_book_outlined),
                  label: ru ? 'Статьи' : 'Articles',
                ),
              ],
            ),
    );
  }
}

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
          tooltip: AppLocalizations.of(context)!.feedbackReports,
          onPressed: () => context.go('/feedback'),
          icon: const Icon(Icons.feedback_outlined),
        ),
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
    this.showExplanation = true,
    this.initialAnswer,
  });
  final PublicQuestion question;
  final ValueChanged<Object> onAnswer;
  final bool submitting;
  final Reveal? reveal;
  final bool showExplanation;
  final StagedAnswer? initialAnswer;
  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  String? single;
  final multiple = <String>{};
  final text = TextEditingController();
  @override
  void initState() {
    super.initState();
    switch (widget.initialAnswer) {
      case SingleChoiceAnswer(:final optionId):
        single = optionId;
      case MultipleChoiceAnswer(:final optionIds):
        multiple.addAll(optionIds);
      case NormalizedTextAnswer(:final text):
        this.text.text = text;
      case null:
        break;
    }
  }

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
    final compact = MediaQuery.sizeOf(context).width < 600;
    final questionImage = _imageMedia(widget.question.media);
    final choices = widget.question.options
        .map(
          (option) => switch (widget.question.kind) {
            AnswerKind.singleChoice => _ChoiceControl(
              label: option.text,
              stableId: option.id,
              selected: single == option.id,
              disabled: disabled,
              correct: widget.reveal?.correctOptionIds.contains(option.id),
              onActivate: () => _selectSingle(option.id),
              child: RadioListTile<String>(
                dense: compact,
                visualDensity: compact
                    ? const VisualDensity(vertical: -1)
                    : null,
                contentPadding: compact
                    ? const EdgeInsets.symmetric(horizontal: 8)
                    : null,
                value: option.id,
                groupValue: single,
                onChanged: disabled ? null : (id) => _selectSingle(id!),
                title: Text(
                  option.text,
                  style: TextStyle(fontSize: compact ? 16 : null, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ),
            AnswerKind.multipleChoice => _ChoiceControl(
              label: option.text,
              stableId: option.id,
              selected: multiple.contains(option.id),
              disabled: disabled,
              correct: widget.reveal?.correctOptionIds.contains(option.id),
              onActivate: () => _toggleMultiple(option.id),
              child: CheckboxListTile(
                dense: compact,
                visualDensity: compact
                    ? const VisualDensity(vertical: -1)
                    : null,
                contentPadding: compact
                    ? const EdgeInsets.symmetric(horizontal: 8)
                    : null,
                value: multiple.contains(option.id),
                onChanged: disabled ? null : (_) => _toggleMultiple(option.id),
                title: Text(
                  option.text,
                  style: TextStyle(fontSize: compact ? 16 : null, color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ),
            AnswerKind.normalizedText => const SizedBox.shrink(),
          },
        )
        .toList();
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 8 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MarkdownBody(
              data: widget.question.stem,
              imageBuilder: (_, _, _) => const SizedBox.shrink(),
              styleSheet: MarkdownStyleSheet.fromTheme(Theme.of(context))
                  .copyWith(
                    p: compact
                        ? Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontSize: 18)
                        : Theme.of(context).textTheme.titleLarge,
                  ),
            ),
            if (questionImage != null) ...[
              const SizedBox(height: 12),
              _QuestionMedia(media: questionImage),
            ],
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
              for (final choice in choices)
                Padding(
                  padding: EdgeInsets.only(top: compact ? 1 : 8),
                  child: choice,
                ),
            if (widget.reveal != null && widget.showExplanation)
              ExplanationPanel(reveal: widget.reveal!),
          ],
        ),
      ),
    );
  }
}

Media? _imageMedia(Iterable<Media> media) {
  for (final item in media) {
    if (item.kind == 'image') return item;
  }
  return null;
}

class _QuestionMedia extends StatelessWidget {
  const _QuestionMedia({required this.media});
  final Media media;

  Uri? get _uri {
    final uri = Uri.tryParse(media.uri);
    return uri != null && uri.scheme == 'https' && uri.host.isNotEmpty
        ? uri
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final uri = _uri;
    final alt = media.alt?.trim();
    final russian = Localizations.localeOf(context).languageCode == 'ru';
    final label = alt == null || alt.isEmpty
        ? (russian ? 'Изображение вопроса' : 'Question image')
        : alt;
    final unavailable = russian
        ? 'Изображение недоступно'
        : 'Image unavailable';
    return SizedBox(
      key: const Key('question-media'),
      height: 80,
      width: double.infinity,
      child: Semantics(
        container: true,
        label: label,
        image: true,
        child: uri == null
            ? _QuestionMediaError(label: unavailable)
            : Image.network(
                uri.toString(),
                fit: BoxFit.contain,
                excludeFromSemantics: true,
                loadingBuilder: (context, child, progress) => progress == null
                    ? child
                    : Center(
                        child: Semantics(
                          label: AppLocalizations.of(context)!.loading,
                          liveRegion: true,
                          child: CircularProgressIndicator(),
                        ),
                      ),
                errorBuilder: (_, _, _) =>
                    _QuestionMediaError(label: unavailable),
              ),
      ),
    );
  }
}

class _QuestionMediaError extends StatelessWidget {
  const _QuestionMediaError({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Center(
    child: Semantics(
      key: const Key('question-media-error'),
      label: label,
      liveRegion: true,
      child: Icon(Icons.broken_image_outlined),
    ),
  );
}

class _ChoiceControl extends StatefulWidget {
  const _ChoiceControl({
    required this.label,
    required this.stableId,
    required this.selected,
    required this.disabled,
    required this.onActivate,
    required this.child,
    this.correct,
  });

  final String label;
  final String stableId;
  final bool selected;
  final bool disabled;
  final VoidCallback onActivate;
  final Widget child;
  final bool? correct;

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
    identifier: widget.stableId,
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
          color: widget.correct == true
              ? Theme.of(context).colorScheme.tertiaryContainer
              : widget.correct == false && widget.selected
              ? Theme.of(context).colorScheme.errorContainer
              : Theme.of(context).colorScheme.surfaceContainerLow,
          border: Border.all(
            color: widget.correct == true
                ? const Color(0xff81c784)
                : widget.correct == false && widget.selected
                ? const Color(0xffcf7770)
                : _focused || widget.selected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outlineVariant,
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48),
            child: widget.child,
          ),
        ),
      ),
    ),
  );
}

String _normalize(String value) =>
    value.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();

class ExplanationPanel extends StatelessWidget {
  const ExplanationPanel({
    super.key,
    required this.reveal,
    this.onBeforeArticleOpen,
  });
  final Reveal reveal;
  final VoidCallback? onBeforeArticleOpen;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Inherit the host surface's text colour; no fill, so contrast stays theirs.
    final color =
        DefaultTextStyle.of(context).style.color ?? theme.colorScheme.onSurface;
    return Semantics(
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        padding: const EdgeInsets.only(left: 12),
        decoration: const BoxDecoration(
          border: Border(left: BorderSide(color: Color(0xff81c784), width: 4)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Color(0xff81c784),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    AppLocalizations.of(context)!.correctAnswerLabel,
                    style: theme.textTheme.labelLarge?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              reveal.answer,
              key: const Key('reveal-answer'),
              style: theme.textTheme.titleLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(reveal.explanation),
            if (reveal.quizId != null &&
                reveal.questionId != null &&
                reveal.revision != null)
              QuestionArticleLink(
                quizId: reveal.quizId,
                questionId: reveal.questionId,
                revision: reveal.revision!.sha256,
                onBeforeOpen: onBeforeArticleOpen,
              ),
          ],
        ),
      ),
    );
  }
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
