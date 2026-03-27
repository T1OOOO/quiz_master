import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:quiz_master/core/localization/l10n_extensions.dart';
import 'package:quiz_master/core/utils/image_utils.dart';
import 'package:quiz_master/features/quiz/domain/entities/quiz_entities.dart'
    hide Feedback;
import 'package:quiz_master/features/quiz/domain/entities/quiz_entities.dart'
    as quiz_entities
    show Feedback;
import 'package:quiz_master/features/quiz/presentation/widgets/question_header.dart';
import 'package:quiz_master/features/quiz/presentation/widgets/answer_options.dart';

class QuestionCard extends StatelessWidget {
  final Question question;
  final int currentIndex;
  final int totalQuestions;
  final int? selectedAnswer;
  final quiz_entities.Feedback? feedback;
  final QuizStats stats;
  final ValueChanged<int> onAnswer;
  final VoidCallback? onNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onReset;
  final VoidCallback? onShuffle;

  const QuestionCard({
    super.key,
    required this.question,
    required this.currentIndex,
    required this.totalQuestions,
    this.selectedAnswer,
    this.feedback,
    required this.stats,
    required this.onAnswer,
    this.onNext,
    this.onPrevious,
    this.onReset,
    this.onShuffle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            QuestionHeader(
              currentIndex: currentIndex,
              totalQuestions: totalQuestions,
              stats: stats,
              difficulty: question.difficulty,
              onReset: onReset,
              onShuffle: onShuffle,
            ),
            const SizedBox(height: 16),

            // Image
            if (question.imageUrl != null) ...[
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    ImageUtils.getImageUrl(question.imageUrl),
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Container(
                        color: Colors.grey[800],
                        child: Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[800],
                        child: const Icon(Icons.image, color: Colors.grey),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Question Text
            MarkdownBody(
              data: question.text,
              styleSheet: MarkdownStyleSheet(
                p: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Answer Options
            AnswerOptions(
              options: question.options,
              selectedAnswer: selectedAnswer,
              feedback: feedback,
              onAnswer: onAnswer,
            ),

            // Explanation
            if (feedback != null && feedback!.explanation != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: feedback!.correct
                      ? Colors.green.withValues(alpha: 0.1)
                      : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: feedback!.correct
                        ? Colors.green.withValues(alpha: 0.3)
                        : Colors.red.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.explanationTitle,
                      style: TextStyle(
                        color: feedback!.correct ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 8),
                    MarkdownBody(
                      data: feedback!.explanation!,
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Navigation Buttons
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onPrevious != null && currentIndex > 0)
                  ElevatedButton.icon(
                    onPressed: onPrevious,
                    icon: const Icon(Icons.arrow_back),
                    label: Text(context.l10n.previous),
                  )
                else
                  const SizedBox.shrink(),
                if (onNext != null && currentIndex < totalQuestions - 1)
                  ElevatedButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.arrow_forward),
                    label: Text(context.l10n.next),
                  )
                else
                  const SizedBox.shrink(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
