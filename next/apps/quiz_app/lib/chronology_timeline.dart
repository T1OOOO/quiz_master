import 'package:flutter/material.dart';

class ChronologyEntry {
  const ChronologyEntry({
    required this.id,
    required this.year,
    required this.date,
    required this.title,
  });
  final String id, date, title;
  final int year;
}

class _ChronologyPractice extends StatelessWidget {
  const _ChronologyPractice({
    required this.first,
    required this.last,
    required this.answer,
    required this.onAnswered,
    required this.reverseChoices,
  });

  final ChronologyEntry first;
  final ChronologyEntry last;
  final String? answer;
  final ValueChanged<String> onAnswered;
  final bool reverseChoices;

  @override
  Widget build(BuildContext context) {
    final russian = Localizations.localeOf(context).languageCode == 'ru';
    String text(String en, String ru) => russian ? ru : en;
    final answered = answer != null && answer!.isNotEmpty;
    final correct = answer == first.id;
    return Card(
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              text('Which happened first?', 'Что произошло раньше?'),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            for (final entry in reverseChoices ? [last, first] : [first, last])
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: answered ? null : () => onAnswered(entry.id),
                    child: Text(entry.title),
                  ),
                ),
              ),
            if (answered)
              Text(
                correct
                    ? text(
                        'Correct: ${first.date} came before ${last.date}.',
                        'Верно: ${first.date} раньше ${last.date}.',
                      )
                    : text(
                        'It happened first: ${first.title} (${first.date}).',
                        'Сначала было: ${first.title} (${first.date}).',
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ChronologyPair {
  const _ChronologyPair(this.first, this.last);

  final ChronologyEntry first;
  final ChronologyEntry last;
}

/// Dates remain explicit: equal card spacing represents order, not elapsed time.
class ChronologyTimeline extends StatefulWidget {
  const ChronologyTimeline({
    super.key,
    required this.entries,
    required this.onSelected,
    this.selectedId,
    this.showEraFilters = false,
    this.showPractice = false,
  });
  final List<ChronologyEntry> entries;
  final ValueChanged<String> onSelected;
  final String? selectedId;
  final bool showEraFilters;
  final bool showPractice;
  @override
  State<ChronologyTimeline> createState() => _ChronologyTimelineState();
}

class _ChronologyTimelineState extends State<ChronologyTimeline> {
  final _scroll = ScrollController();
  double _scale = 1;
  String? _selectedEra;
  String? _practiceAnswer;
  _ChronologyPair? _practicePair;
  var _practiceReverse = false;
  var _nextPracticePair = 0;

  static String _eraForYear(int year) {
    if (year < 500) return 'ancient';
    if (year < 1500) return 'medieval';
    if (year < 1800) return 'earlyModern';
    if (year < 1900) return 'nineteenthCentury';
    if (year < 1914) return 'earlyTwentiethCentury';
    if (year < 1945) return 'firstHalfTwentiethCentury';
    return 'modern';
  }

  String _text(BuildContext context, String en, String ru) =>
      Localizations.localeOf(context).languageCode == 'ru' ? ru : en;

  String _eraLabel(BuildContext context, String era) {
    return switch (era) {
      'ancient' => _text(context, 'Ancient world', 'Древний мир'),
      'medieval' => _text(context, 'Middle Ages', 'Средневековье'),
      'earlyModern' => _text(context, 'Early modern era', 'Раннее Новое время'),
      'nineteenthCentury' => _text(context, '19th century', 'XIX век'),
      'earlyTwentiethCentury' =>
        _text(context, 'Early 20th century', 'Начало XX века'),
      'firstHalfTwentiethCentury' =>
        _text(context, 'First half of the 20th century', 'Первая половина XX века'),
      _ => _text(context, 'Modern era', 'Современность'),
    };
  }

  List<_ChronologyPair> _practicePairs(List<ChronologyEntry> entries) {
    final pairs = <_ChronologyPair>[];
    for (var firstIndex = 0; firstIndex < entries.length; firstIndex++) {
      for (var lastIndex = firstIndex + 1;
          lastIndex < entries.length;
          lastIndex++) {
        if (entries[firstIndex].year != entries[lastIndex].year) {
          pairs.add(_ChronologyPair(entries[firstIndex], entries[lastIndex]));
        }
      }
    }
    return pairs;
  }

  void _chooseEra(String? era) {
    setState(() {
      _selectedEra = era;
      _practicePair = null;
      _practiceAnswer = null;
    });
  }

  void _startPractice(List<_ChronologyPair> pairs) {
    setState(() {
      final pairIndex = _nextPracticePair % pairs.length;
      _practicePair = pairs[pairIndex];
      _practiceReverse = pairIndex.isOdd;
      _nextPracticePair++;
      _practiceAnswer = null;
    });
  }
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allEntries = [...widget.entries]
      ..sort((a, b) => a.year.compareTo(b.year));
    final eras = {
      for (final entry in allEntries) _eraForYear(entry.year),
    }.toList();
    final entries = _selectedEra == null
        ? allEntries
        : allEntries
              .where((entry) => _eraForYear(entry.year) == _selectedEra)
              .toList();
    final practicePairs = _practicePairs(entries);
    final colors = Theme.of(context).colorScheme;
    final textScaler = MediaQuery.textScalerOf(context);
    final textStyle = DefaultTextStyle.of(context).style;
    final dateStyle = textStyle.copyWith(
      color: colors.primary,
      fontWeight: FontWeight.bold,
    );
    final entryWidth = 164 * _scale;
    double heightOf(String text, TextStyle style, {int? maxLines}) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: Directionality.of(context),
        textScaler: textScaler,
        locale: Localizations.maybeLocaleOf(context),
        maxLines: maxLines,
        ellipsis: maxLines == null ? null : '…',
      )..layout(maxWidth: entryWidth - 16);
      final height = painter.height;
      painter.dispose();
      return height;
    }

    double dateHeight = 0;
    double titleHeight = 0;
    for (final entry in entries) {
      final date = heightOf(entry.date, dateStyle);
      final title = heightOf(entry.title, textStyle, maxLines: 3);
      if (date > dateHeight) dateHeight = date;
      if (title > titleHeight) titleHeight = title;
    }
    final contentHeight = 24 + dateHeight + 10 + 20 + 16 + titleHeight;
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _text(context, 'Timeline', 'Линия времени'),
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: _text(context, 'Zoom out', 'Уменьшить шкалу'),
                  onPressed: _scale > .8
                      ? () =>
                            setState(() => _scale = (_scale - .2).clamp(.8, 2))
                      : null,
                  icon: const Icon(Icons.remove),
                ),
                IconButton(
                  tooltip: _text(context, 'Zoom in', 'Увеличить шкалу'),
                  onPressed: _scale < 2
                      ? () =>
                            setState(() => _scale = (_scale + .2).clamp(.8, 2))
                      : null,
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              _text(
                context,
                'Scroll horizontally and select events. Gaps are compressed.',
                'Листайте по горизонтали и выбирайте события. Интервалы между датами сжаты.',
              ),
              style: TextStyle(fontSize: 12),
            ),
          ),
          if (widget.showEraFilters)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  ChoiceChip(
                    label: Text(_text(context, 'All eras', 'Все эпохи')),
                    selected: _selectedEra == null,
                    onSelected: (_) => _chooseEra(null),
                  ),
                  for (final era in eras)
                    ChoiceChip(
                      label: Text(_eraLabel(context, era)),
                      selected: _selectedEra == era,
                      onSelected: (_) => _chooseEra(era),
                    ),
                ],
              ),
            ),
          if (widget.showPractice && practicePairs.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  key: const Key('chronology-practice'),
                  onPressed: () => _startPractice(practicePairs),
                  icon: const Icon(Icons.quiz_outlined),
                  label: Text(_text(context, 'Practice', 'Тренировка')),
                ),
              ),
            ),
          if (_practicePair != null)
            _ChronologyPractice(
              first: _practicePair!.first,
              last: _practicePair!.last,
              answer: _practiceAnswer,
              onAnswered: (id) => setState(() => _practiceAnswer = id),
              reverseChoices: _practiceReverse,
            ),
          SizedBox(
            height: contentHeight > textScaler.scale(180)
                ? contentHeight
                : textScaler.scale(180),
            child: Scrollbar(
              controller: _scroll,
              child: ListView.builder(
                key: const Key('chronology-timeline'),
                controller: _scroll,
                scrollDirection: Axis.horizontal,
                itemCount: entries.length,
                itemBuilder: (context, index) {
                  final entry = entries[index];
                  final selected = widget.selectedId == entry.id;
                  return SizedBox(
                    width: entryWidth,
                    child: InkWell(
                      key: Key('chronology-entry-${entry.id}'),
                      onTap: () => widget.onSelected(entry.id),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Column(
                          children: [
                            SizedBox(
                              height: dateHeight,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Text(
                                    entry.date,
                                    textAlign: TextAlign.center,
                                    style: dateStyle,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            SizedBox(
                              height: 20,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Divider(color: colors.primary),
                                  ),
                                  Icon(
                                    selected
                                        ? Icons.radio_button_checked
                                        : Icons.circle,
                                    size: selected ? 20 : 12,
                                    color: colors.primary,
                                  ),
                                  Expanded(
                                    child: Divider(color: colors.primary),
                                  ),
                                ],
                              ),
                            ),
                            Flexible(
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  entry.title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          if (entries.isEmpty)
            Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                _text(
                  context,
                  'There are no events in this era. Change the filter.',
                  'В этом периоде пока нет событий. Измените фильтр.',
                ),
              ),
            ),
        ],
      ),
    );
  }
}
