/// Editorial learning material is separate from ranked question/grading DTOs.
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

const questionArticlesAsset = 'assets/study/question-articles.json';

class QuestionArticle {
  const QuestionArticle({
    required this.id,
    required this.title,
    required this.body,
    required this.sources,
    required this.targetRefs,
    required this.questionRefs,
  });
  final String id, title, body;
  final List<Map<String, dynamic>> sources, targetRefs, questionRefs;

  factory QuestionArticle.fromJson(Map<String, dynamic> row) {
    String text(String key) {
      final value = row[key];
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('article $key');
      }
      return value;
    }

    List<Map<String, dynamic>> records(String key) {
      final value = row[key];
      if (value is! List || value.any((item) => item is! Map)) {
        throw FormatException('article $key');
      }
      return value
          .map((item) => Map<String, dynamic>.from(item as Map))
          .toList();
    }

    if (row['status'] != 'accepted') {
      throw const FormatException('unreviewed article');
    }
    final sources = records('source_links');
    if (sources.length < 2) throw const FormatException('article sources');
    for (final source in sources) {
      final uri = Uri.tryParse(
        source['url'] is String ? source['url'] as String : '',
      );
      if (uri == null ||
          uri.scheme != 'https' ||
          uri.host.isEmpty ||
          source['title'] is! String ||
          (source['title'] as String).trim().isEmpty) {
        throw const FormatException('article source');
      }
    }
    return QuestionArticle(
      id: text('id'),
      title: text('title_ru'),
      body: text('body_ru'),
      sources: sources,
      targetRefs: records('target_refs'),
      questionRefs: records('question_refs'),
    );
  }
}

class QuestionArticles {
  QuestionArticles(this.articles);
  final List<QuestionArticle> articles;

  factory QuestionArticles.decode(String source) {
    final json = jsonDecode(source);
    if (json is! Map ||
        json['schema_version'] != 'qm-question-articles/v1' ||
        json['articles'] is! List) {
      throw const FormatException('article catalog');
    }
    final items = (json['articles'] as List)
        .map(
          (item) =>
              QuestionArticle.fromJson(Map<String, dynamic>.from(item as Map)),
        )
        .toList();
    if (items.map((item) => item.id).toSet().length != items.length) {
      throw const FormatException('duplicate article');
    }
    return QuestionArticles(items);
  }

  QuestionArticle? forTarget(String domain, String id) {
    for (final article in articles) {
      if (article.targetRefs.any(
        (ref) =>
            ref['kind'] == 'quizipedia' &&
            ref['domain'] == domain &&
            ref['target_id'] == id,
      )) {
        return article;
      }
    }
    return null;
  }

  QuestionArticle? forQuestion(
    String quizId,
    String questionId,
    String revision,
  ) {
    for (final article in articles) {
      if (article.questionRefs.any(
        (ref) =>
            ref['quiz_id'] == quizId &&
            ref['question_id'] == questionId &&
            ref['revision_sha256'] == revision,
      )) {
        return article;
      }
    }
    return null;
  }
}

// Cache per bundle, so tests and alternate asset bundles do not share content.
final _catalogLoads = Expando<Future<QuestionArticles>>();
Future<QuestionArticles> loadQuestionArticles(AssetBundle bundle) =>
    _catalogLoads[bundle] ??= bundle
        .loadString(questionArticlesAsset)
        .then(QuestionArticles.decode);

class QuestionArticleLink extends StatefulWidget {
  const QuestionArticleLink({
    super.key,
    this.domain,
    this.targetId,
    this.quizId,
    this.questionId,
    this.revision,
    this.bundle,
    this.onBeforeOpen,
  });
  final String? domain, targetId, quizId, questionId, revision;
  final AssetBundle? bundle;
  final VoidCallback? onBeforeOpen;
  @override
  State<QuestionArticleLink> createState() => _QuestionArticleLinkState();
}

class _QuestionArticleLinkState extends State<QuestionArticleLink> {
  bool get _ru => Localizations.localeOf(context).languageCode == 'ru';

  @override
  Widget build(BuildContext context) => FutureBuilder<QuestionArticles>(
    future: loadQuestionArticles(widget.bundle ?? rootBundle),
    builder: (context, snapshot) {
      if (!snapshot.hasData) return const SizedBox.shrink();
      final catalog = snapshot.data!;
      final article = widget.domain != null && widget.targetId != null
          ? catalog.forTarget(widget.domain!, widget.targetId!)
          : widget.quizId != null &&
                widget.questionId != null &&
                widget.revision != null
          ? catalog.forQuestion(
              widget.quizId!,
              widget.questionId!,
              widget.revision!,
            )
          : null;
      if (article == null) return const SizedBox.shrink();
      return Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          key: ValueKey('article-link-${article.id}'),
          style: TextButton.styleFrom(minimumSize: const Size(48, 48)),
          icon: const Icon(Icons.menu_book_outlined),
          label: Text(_ru ? 'Узнать больше' : 'Read more (Russian)'),
          onPressed: () {
            widget.onBeforeOpen?.call();
            showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              useSafeArea: true,
              showDragHandle: true,
              builder: (_) => QuestionArticleReader(article: article),
            );
          },
        ),
      );
    },
  );
}

class QuestionArticleReader extends StatelessWidget {
  const QuestionArticleReader({super.key, required this.article});
  final QuestionArticle article;
  @override
  Widget build(BuildContext context) {
    const ink = Color(0xff3f2f23),
        paper = Color(0xffead9bf),
        link = Color(0xff005f52);
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final theme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: link, surface: paper),
      textTheme: Theme.of(context).textTheme
          .apply(bodyColor: ink, displayColor: ink),
    );
    return Theme(
      data: theme,
      child: Material(
        color: paper,
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .88,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        article.title,
                        style: theme.textTheme.titleLarge,
                      ),
                    ),
                    IconButton(
                      tooltip: ru ? 'Закрыть статью' : 'Close article',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      MarkdownBody(
                        data: article.body,
                        selectable: true,
                        styleSheet: MarkdownStyleSheet.fromTheme(theme)
                            .copyWith(
                              p: theme.textTheme.bodyLarge!.copyWith(
                                height: 1.55,
                              ),
                              a: const TextStyle(
                                color: link,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                        onTapLink: (_, url, _) => _openArticleSource(url),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        ru
                            ? 'Источники и дальнейшее чтение'
                            : 'Sources and further reading',
                        style: theme.textTheme.titleMedium,
                      ),
                      for (final source in article.sources)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(Icons.open_in_new, color: link),
                          title: Text(
                            source['title'] as String,
                            style: const TextStyle(color: link),
                          ),
                          subtitle: Text(
                            Uri.parse(source['url'] as String).host,
                          ),
                          onTap: () =>
                              _openArticleSource(source['url'] as String),
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
}

Future<void> _openArticleSource(String? url) async {
  final uri = Uri.tryParse(url ?? '');
  if (uri != null && uri.scheme == 'https' && uri.host.isNotEmpty) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
