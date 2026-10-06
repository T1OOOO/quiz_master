part of 'main.dart';

String feedbackRoute(Uri uri) {
  if (uri.path.startsWith('/join/')) return '/join/[invite]';
  // Send only known public routes; arbitrary paths may contain credentials.
  final path = uri.path;
  if (RegExp(r'^/(library|gallery|history|quizipedia|study)?$')
          .hasMatch(path) ||
      RegExp(r'^/(quiz|study)/[a-zA-Z0-9_.-]+(/practice)?$').hasMatch(path)) {
    return path;
  }
  return '/';
}

class _FeedbackOverlay extends ConsumerStatefulWidget {
  const _FeedbackOverlay({required this.router, required this.child});
  final GoRouter router;
  final Widget child;
  @override
  ConsumerState<_FeedbackOverlay> createState() => _FeedbackOverlayState();
}

class _FeedbackOverlayState extends ConsumerState<_FeedbackOverlay> {
  final _boundary = GlobalKey();
  bool _opening = false;

  Future<Uint8List?> _capture() async {
    try {
      final boundary = _boundary.currentContext?.findRenderObject();
      if (boundary is! RenderRepaintBoundary || boundary.debugNeedsPaint) {
        return null;
      }
      final area = boundary.size.width * boundary.size.height;
      if (area <= 0) return null;
      // At most four million pixels, even on high-DPI displays.
      final ratio = min(
        MediaQuery.devicePixelRatioOf(context),
        sqrt(3900000 / area),
      );
      final shot = await boundary.toImage(pixelRatio: ratio);
      try {
        final bytes = await shot.toByteData(format: ui.ImageByteFormat.png);
        if (bytes == null || bytes.lengthInBytes > 2 * 1024 * 1024) return null;
        return bytes.buffer.asUint8List(
          bytes.offsetInBytes,
          bytes.lengthInBytes,
        );
      } finally {
        shot.dispose();
      }
    } catch (_) {
      return null;
    }
  }

  Future<void> _open() async {
    if (_opening) return;
    final uri = widget.router.routeInformationProvider.value.uri;
    if (uri.path == '/feedback') return;
    final navContext = widget.router.routerDelegate.navigatorKey.currentContext;
    if (navContext == null) return;
    setState(() => _opening = true);
    final route = feedbackRoute(uri);
    final size = MediaQuery.sizeOf(context);
    final details = <String, Object>{
      'route': route,
      'viewport': <String, num>{
        'width': size.width,
        'height': size.height,
        'dpr': MediaQuery.devicePixelRatioOf(context),
      },
      'locale': Localizations.localeOf(context).toLanguageTag(),
      'theme': Theme.of(context).brightness == Brightness.dark
          ? 'dark'
          : 'light',
      'platform': kIsWeb ? 'web' : Theme.of(context).platform.name,
      'app_version': const String.fromEnvironment(
        'QM_BUILD_ID',
        defaultValue: '1.0.0+1',
      ),
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
    final items = <String>['screen:$route'];
    final journey = ref.read(journeyProvider);
    final quiz = journey.catalog?.quiz;
    if (quiz != null && route == '/quiz/${quiz.id}' && !journey.loading) {
      details['quiz_id'] = quiz.id;
      items.add('quiz:${quiz.id}');
      final attempt = journey.attempt;
      if (attempt != null &&
          journey.finish == null &&
          journey.index >= 0 &&
          journey.index < attempt.snapshots.length) {
        final id = attempt.snapshots[journey.index].questionId;
        final questions = quiz.questions.where((question) => question.id == id);
        if (questions.isNotEmpty) {
          details['question_id'] = id;
          details['attempt_id'] = attempt.id;
          details['question_text'] = String.fromCharCodes(
            questions.first.stem.runes.take(4000),
          );
          items.add('question:$id');
        }
      }
    }
    final client = ref.read(quizApiProvider);
    // Capture before adding a modal, and never capture the operator page.
    final png = route == '/join/[invite]'
        ? null
        : await _capture().timeout(
            const Duration(seconds: 3),
            onTimeout: () => null,
          );
    if (!mounted) return;
    if (widget.router.routeInformationProvider.value.uri != uri) {
      setState(() => _opening = false);
      return;
    }
    try {
      if (!navContext.mounted) return;
      final sent = await showDialog<bool>(
        context: navContext,
        barrierDismissible: false,
        builder: (_) => _GlobalFeedbackDialog(
          client: client,
          details: details,
          items: items,
          screenshot: png,
        ),
      );
      if (sent == true && navContext.mounted) {
        ScaffoldMessenger.of(navContext).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(navContext)!.feedbackThankYouForYourFeedback,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.router.routeInformationProvider,
    builder: (context, _) => Stack(
      children: [
        RepaintBoundary(key: _boundary, child: widget.child),
        if (widget.router.routeInformationProvider.value.uri.path !=
            '/feedback')
          PositionedDirectional(
            end: 12,
            bottom: 88 + MediaQuery.viewInsetsOf(context).bottom,
            child: SafeArea(
              child: FloatingActionButton.small(
                heroTag: 'feedback',
                tooltip: AppLocalizations.of(context)!.feedbackSendFeedback,
                onPressed: _opening ? null : _open,
                child: const Icon(Icons.support_agent),
              ),
            ),
          ),
      ],
    ),
  );
}

class _GlobalFeedbackDialog extends StatefulWidget {
  const _GlobalFeedbackDialog({
    required this.client,
    required this.details,
    required this.items,
    this.screenshot,
  });
  final QuizApiClient client;
  final Map<String, Object> details;
  final List<String> items;
  final Uint8List? screenshot;
  @override
  State<_GlobalFeedbackDialog> createState() => _GlobalFeedbackDialogState();
}

class _GlobalFeedbackDialogState extends State<_GlobalFeedbackDialog> {
  final _comment = TextEditingController();
  String _type = 'ui';
  bool _attach = false;
  bool _sending = false;
  bool _failed = false;
  Map<String, Object>? _payload;
  void _changed() => setState(() {
    _payload = null;
    _failed = false;
  });
  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (_sending) return;
    final comment = _comment.text.trim();
    if (comment.isEmpty || comment.runes.length > 5000) return;
    _payload ??= <String, Object>{
      'request_id':
          'frq_${List.generate(16, (_) => Random.secure().nextInt(256).toRadixString(16).padLeft(2, '0')).join()}',
      'type': _type,
      'comment': comment,
      'item_ids': widget.items,
      'context': widget.details,
      if (_attach && widget.screenshot != null)
        'screenshot': base64Encode(widget.screenshot!),
    };
    setState(() {
      _sending = true;
      _failed = false;
    });
    try {
      await widget.client.submitReport(_payload!);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _failed = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final comment = _comment.text.trim();
    return PopScope(
      canPop: !_sending,
      child: AlertDialog(
        title: Text(AppLocalizations.of(context)!.feedbackFeedback),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _type,
                  items: [
                    DropdownMenuItem(
                      value: 'ui',
                      child: Text(
                        AppLocalizations.of(context)!
                            .feedbackApplicationProblem,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'content',
                      child: Text(
                        AppLocalizations.of(context)!.feedbackQuestionProblem,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'idea',
                      child: Text(
                        AppLocalizations.of(context)!.feedbackSuggestion,
                      ),
                    ),
                  ],
                  onChanged: _sending
                      ? null
                      : (value) {
                          _type = value!;
                          _changed();
                        },
                ),
                TextField(
                  controller: _comment,
                  enabled: !_sending,
                  maxLength: 5000,
                  minLines: 3,
                  maxLines: 6,
                  onChanged: (_) => _changed(),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.feedbackComment,
                  ),
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _attach,
                  onChanged: _sending || widget.screenshot == null
                      ? null
                      : (value) {
                          _attach = value ?? false;
                          _changed();
                        },
                  title: Text(
                    AppLocalizations.of(context)!.feedbackAttachScreenshot,
                  ),
                ),
                if (widget.screenshot == null)
                  Text(
                    AppLocalizations.of(context)!
                        .feedbackScreenshotUnavailableYouCanSendAComment,
                  ),
                if (_attach && widget.screenshot != null)
                  Image.memory(
                    widget.screenshot!,
                    height: 160,
                    fit: BoxFit.contain,
                  ),
                if (_failed)
                  Text(
                    AppLocalizations.of(context)!
                        .feedbackCouldNotSendYourTextIsSavedPleaseRetry,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _sending ? null : () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context)!.feedbackCancel),
          ),
          FilledButton(
            onPressed:
                _sending || comment.isEmpty || comment.runes.length > 5000
                ? null
                : _send,
            child: Text(
              _sending
                  ? (AppLocalizations.of(context)!.feedbackSending)
                  : (AppLocalizations.of(context)!.feedbackSend),
            ),
          ),
        ],
      ),
    );
  }
}
