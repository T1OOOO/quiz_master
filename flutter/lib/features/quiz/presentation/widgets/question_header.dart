import 'package:flutter/material.dart';
import 'package:quiz_master/core/localization/l10n_extensions.dart';
import 'package:quiz_master/features/quiz/domain/entities/quiz_entities.dart';

class QuestionHeader extends StatelessWidget {
  final int currentIndex;
  final int totalQuestions;
  final QuizStats stats;
  final int? difficulty;
  final VoidCallback? onReset;
  final VoidCallback? onShuffle;

  const QuestionHeader({
    super.key,
    required this.currentIndex,
    required this.totalQuestions,
    required this.stats,
    this.difficulty,
    this.onReset,
    this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 360;

        final statsWrap = Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _StatChip(
              backgroundColor: Colors.blue.withValues(alpha: 0.1),
              icon: '❓',
              text: '${currentIndex + 1}/$totalQuestions',
              textColor: Colors.blue,
            ),
            _StatChip(
              backgroundColor: Colors.green.withValues(alpha: 0.1),
              icon: '✅',
              text: '${stats.correct}',
              textColor: Colors.green,
            ),
            _StatChip(
              backgroundColor: Colors.red.withValues(alpha: 0.1),
              icon: '❌',
              text: '${stats.incorrect}',
              textColor: Colors.red,
            ),
            if (difficulty != null)
              _StatChip(
                backgroundColor: Colors.purple.withValues(alpha: 0.1),
                icon: '⚡',
                text: '$difficulty/10',
                textColor: Colors.purple,
              ),
          ],
        );

        final actions = Wrap(
          spacing: 4,
          children: [
            if (onReset != null)
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: onReset,
                tooltip: context.l10n.reset,
              ),
            if (onShuffle != null)
              IconButton(
                icon: const Icon(Icons.shuffle, size: 20),
                onPressed: onShuffle,
                tooltip: context.l10n.shuffle,
              ),
          ],
        );

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: isCompact
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    statsWrap,
                    if (onReset != null || onShuffle != null) ...[
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerRight, child: actions),
                    ],
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: statsWrap),
                    if (onReset != null || onShuffle != null)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: actions,
                      ),
                  ],
                ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.backgroundColor,
    required this.icon,
    required this.text,
    required this.textColor,
  });

  final Color backgroundColor;
  final String icon;
  final String text;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
