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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Stats
          Row(
            children: [
              // Progress
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('❓', style: TextStyle(fontSize: 13)),
                    const SizedBox(width: 4),
                    Text(
                      '${currentIndex + 1}/$totalQuestions',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Correct
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('✅', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      '${stats.correct}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Incorrect
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Text('❌', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text(
                      '${stats.incorrect}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
              ),

              // Difficulty
              if (difficulty != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Text('⚡', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        '$difficulty/10',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          // Right: Actions
          Row(
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
          ),
        ],
      ),
    );
  }
}
