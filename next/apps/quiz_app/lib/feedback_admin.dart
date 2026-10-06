part of 'main.dart';

class FeedbackAdminPage extends ConsumerStatefulWidget {
  const FeedbackAdminPage({super.key});
  @override
  ConsumerState<FeedbackAdminPage> createState() => _FeedbackAdminPageState();
}

class _FeedbackAdminPageState extends ConsumerState<FeedbackAdminPage> {
  final _token = TextEditingController();
  late final Dio _dio;
  @override
  void initState() {
    super.initState();
    _dio = Dio(
      BaseOptions(
        baseUrl: ref.read(quizApiProvider).dio.options.baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );
  }

  String? _credential;
  String _status = 'open';
  bool _busy = false, _failed = false;
  int _generation = 0, _offset = 0, _total = 0;
  List<Map<String, dynamic>> _reports = [];
  Options get _options => Options(
    headers: {
      'Authorization': 'Bearer $_credential',
      'Cache-Control': 'no-store',
    },
  );
  bool _current(int generation) =>
      mounted && _credential != null && generation == _generation;

  @override
  void dispose() {
    _generation++;
    _credential = null;
    _token.dispose();
    _dio.close(force: true);
    super.dispose();
  }

  void _logout() {
    setState(() {
      _generation++;
      _credential = null;
      _token.clear();
      _reports = [];
      _offset = 0;
      _total = 0;
      _busy = false;
      _failed = false;
    });
  }

  Future<void> _readPage(int generation, int offset) async {
    final response = await _dio.get<Object>(
      '/v1/admin/reports',
      queryParameters: {'status': _status, 'limit': 50, 'offset': offset},
      options: _options,
    );
    final page = _map(response.data);
    final reports = (page['reports'] as List).map((r) => _map(r)).toList();
    if (_current(generation)) {
      setState(() {
        _reports = reports;
        _offset = page['offset'] as int;
        _total = page['total'] as int;
      });
    }
  }

  Future<void> _load({int? offset}) async {
    if (_busy || _credential == null) return;
    final generation = _generation;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      await _readPage(generation, offset ?? _offset);
    } catch (_) {
      if (_current(generation)) setState(() => _failed = true);
    } finally {
      if (_current(generation)) setState(() => _busy = false);
    }
  }

  Future<void> _mutate(String id, {String? status}) async {
    if (_busy || _credential == null) return;
    final generation = _generation;
    setState(() {
      _busy = true;
      _failed = false;
    });
    try {
      if (status == null) {
        await _dio.delete<Object>('/v1/admin/reports/$id', options: _options);
      } else {
        await _dio.post<Object>(
          '/v1/admin/reports/$id/status',
          data: {'status': status},
          options: _options,
        );
      }
      if (_current(generation)) await _readPage(generation, 0);
    } catch (_) {
      if (_current(generation)) setState(() => _failed = true);
    } finally {
      if (_current(generation)) setState(() => _busy = false);
    }
  }

  Future<void> _delete(String id) async {
    final generation = _generation;
    final yes = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.feedbackDeleteReport),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(AppLocalizations.of(context)!.feedbackCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(AppLocalizations.of(context)!.feedbackDelete),
          ),
        ],
      ),
    );
    if (yes == true && _current(generation)) await _mutate(id);
  }

  Future<void> _detail(Map<String, dynamic> report) async {
    final generation = _generation;
    // The future belongs to this modal; screenshot bytes leave memory with it.
    final Future<Response<List<int>>>? screenshot =
        report['has_screenshot'] == true
        ? _dio.get<List<int>>(
            '/v1/admin/reports/${report['id']}/screenshot',
            options: _options.copyWith(responseType: ResponseType.bytes),
          )
        : null;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.feedbackReport),
        content: SizedBox(
          width: 600,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SelectableText(
                  '${report['comment']}\n\n${const JsonEncoder.withIndent('  ').convert(report['context'])}',
                ),
                if (screenshot != null)
                  FutureBuilder<Response<List<int>>>(
                    future: screenshot,
                    builder: (_, snapshot) {
                      if (!_current(generation)) return const SizedBox();
                      if (snapshot.hasError) {
                        return Text(
                          AppLocalizations.of(context)!
                              .feedbackScreenshotUnavailable,
                        );
                      }
                      if (!snapshot.hasData) {
                        return const LinearProgressIndicator();
                      }
                      final bytes = snapshot.data!.data;
                      if (bytes == null ||
                          bytes.isEmpty ||
                          bytes.length > 2 * 1024 * 1024) {
                        return Text(
                          AppLocalizations.of(context)!
                              .feedbackScreenshotUnavailable,
                        );
                      }
                      return InteractiveViewer(
                        child: Image.memory(
                          Uint8List.fromList(bytes),
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => Text(
                            AppLocalizations.of(context)!
                                .feedbackScreenshotUnavailable,
                          ),
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(AppLocalizations.of(context)!.feedbackClose),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      leading: IconButton(
        tooltip: AppLocalizations.of(context)!.feedbackAllQuizzes,
        icon: const Icon(Icons.arrow_back),
        onPressed: () => context.go('/library'),
      ),
      title: Text(AppLocalizations.of(context)!.feedbackReports),
      actions: [
        if (_credential != null) ...[
          IconButton(
            tooltip: AppLocalizations.of(context)!.feedbackRefresh,
            onPressed: _busy ? null : () => _load(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: AppLocalizations.of(context)!.feedbackLogout,
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
        ],
      ],
    ),
    body: SafeArea(
      child: _credential == null
          ? Center(
              child: SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: _token,
                          obscureText: true,
                          enableSuggestions: false,
                          autocorrect: false,
                          decoration: InputDecoration(
                            labelText: AppLocalizations.of(context)!
                                .feedbackOperatorToken,
                          ),
                        ),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () {
                            if (_token.text.isNotEmpty) {
                              setState(() {
                                _credential = _token.text;
                                _token.clear();
                                _generation++;
                              });
                              _load(offset: 0);
                            }
                          },
                          child: Text(
                            AppLocalizations.of(context)!.feedbackSignIn,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : Column(
              children: [
                DropdownButton<String>(
                  value: _status,
                  items: [
                    DropdownMenuItem(
                      value: 'open',
                      child: Text(AppLocalizations.of(context)!.feedbackOpen),
                    ),
                    DropdownMenuItem(
                      value: 'resolved',
                      child: Text(
                        AppLocalizations.of(context)!.feedbackResolved,
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'all',
                      child: Text(AppLocalizations.of(context)!.feedbackAll),
                    ),
                  ],
                  onChanged: _busy
                      ? null
                      : (value) {
                          setState(() => _status = value!);
                          _load(offset: 0);
                        },
                ),
                if (_busy) const LinearProgressIndicator(),
                if (_failed)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      AppLocalizations.of(context)!
                          .feedbackOperationFailedCheckTheTokenAndRetry,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ),
                Expanded(
                  child: _reports.isEmpty
                      ? Center(
                          child: Text(
                            AppLocalizations.of(context)!.feedbackNoReports,
                          ),
                        )
                      : ListView.builder(
                          itemCount: _reports.length,
                          itemBuilder: (_, index) {
                            final report = _reports[index];
                            final id = report['id'] as String;
                            return ListTile(
                              title: Text(
                                '${report['type']}: ${report['comment']}',
                              ),
                              subtitle: Text(
                                '${report['status']} · ${report['created_at']}',
                              ),
                              onTap: _busy ? null : () => _detail(report),
                              trailing: PopupMenuButton<String>(
                                enabled: !_busy,
                                onSelected: (value) => value == 'delete'
                                    ? _delete(id)
                                    : _mutate(id, status: value),
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: report['status'] == 'open'
                                        ? 'resolved'
                                        : 'open',
                                    child: Text(
                                      report['status'] == 'open'
                                          ? AppLocalizations.of(context)!
                                                .feedbackResolve
                                          : AppLocalizations.of(context)!
                                                .feedbackReopen,
                                    ),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(
                                      AppLocalizations.of(context)!
                                          .feedbackDelete,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: _busy || _offset == 0
                          ? null
                          : () => _load(offset: max(0, _offset - 50)),
                      child: Text(
                        AppLocalizations.of(context)!.feedbackPrevious,
                      ),
                    ),
                    Text('$_offset / $_total'),
                    TextButton(
                      onPressed: _busy || _offset + 50 >= _total
                          ? null
                          : () => _load(offset: _offset + 50),
                      child: Text(AppLocalizations.of(context)!.feedbackNext),
                    ),
                  ],
                ),
              ],
            ),
    ),
  );
}
