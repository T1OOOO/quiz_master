import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:quiz_master/features/quiz/domain/entities/quiz_entities.dart'
    as quiz_entities
    show Feedback;

class AnswerOptions extends StatelessWidget {
  final List<String> options;
  final int? selectedAnswer;
  final quiz_entities.Feedback? feedback;
  final ValueChanged<int> onAnswer;

  const AnswerOptions({
    super.key,
    required this.options,
    this.selectedAnswer,
    this.feedback,
    required this.onAnswer,
  });

  OptionStatus _getOptionStatus(int index) {
    if (feedback == null) {
      return selectedAnswer == index
          ? OptionStatus.selected
          : OptionStatus.neutral;
    }

    final currentOptionText = options[index];
    if (feedback!.correctText == currentOptionText) {
      return OptionStatus.correct;
    }
    if (selectedAnswer == index && !feedback!.correct) {
      return OptionStatus.incorrect;
    }
    return OptionStatus.neutral;
  }

  @override
  Widget build(BuildContext context) {
    final maxLength = options
        .map((opt) => opt.length)
        .reduce((a, b) => a > b ? a : b);
    final useSingleColumn = maxLength > 50;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final option = entry.value;
        final status = _getOptionStatus(index);

        Color backgroundColor;
        Color borderColor;
        Color textColor;

        switch (status) {
          case OptionStatus.selected:
            backgroundColor = Colors.blue.withValues(alpha: 0.1);
            borderColor = Colors.blue.withValues(alpha: 0.3);
            textColor = Colors.blue;
            break;
          case OptionStatus.correct:
            backgroundColor = Colors.green.withValues(alpha: 0.1);
            borderColor = Colors.green.withValues(alpha: 0.3);
            textColor = Colors.green;
            break;
          case OptionStatus.incorrect:
            backgroundColor = Colors.red.withValues(alpha: 0.1);
            borderColor = Colors.red.withValues(alpha: 0.3);
            textColor = Colors.red;
            break;
          case OptionStatus.neutral:
            backgroundColor = Colors.grey.withValues(alpha: 0.1);
            borderColor = Colors.white.withValues(alpha: 0.1);
            textColor = Colors.white;
            break;
        }

        return GestureDetector(
          onTap: feedback == null ? () => onAnswer(index) : null,
          child: Container(
            width: useSingleColumn ? double.infinity : null,
            constraints: useSingleColumn
                ? null
                : const BoxConstraints(minWidth: 150, maxWidth: 200),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: borderColor),
                  ),
                  child: Center(
                    child: Text(
                      String.fromCharCode(65 + index),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: MarkdownBody(
                    data: option,
                    styleSheet: MarkdownStyleSheet(
                      p: TextStyle(
                        color: textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

enum OptionStatus { neutral, selected, correct, incorrect }
