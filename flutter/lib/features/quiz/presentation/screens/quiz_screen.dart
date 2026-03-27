import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:quiz_master/core/localization/l10n_extensions.dart';
import 'package:quiz_master/core/theme/theme_config.dart';
import 'package:quiz_master/core/theme/theme_provider.dart';
import 'package:quiz_master/features/quiz/presentation/providers/quiz_providers.dart';
import 'package:quiz_master/features/quiz/presentation/widgets/question_card.dart';

class QuizScreen extends ConsumerStatefulWidget {
  final String quizId;

  const QuizScreen({super.key, required this.quizId});

  @override
  ConsumerState<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends ConsumerState<QuizScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quizStateProvider.notifier).initQuiz(widget.quizId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizStateProvider);
    final themeType = ref.watch(themeProvider);
    final themeConfig = themeConfigs[themeType]!;
    final isHoliday = themeType == ThemeType.holiday;

    if (quizState.status == QuizStatus.loading) {
      return Scaffold(
        backgroundColor: themeConfig.primaryColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              Text(
                context.l10n.loading,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      );
    }

    if (quizState.status == QuizStatus.error) {
      return Scaffold(
        backgroundColor: themeConfig.primaryColor,
        appBar: AppBar(
          title: Text(context.l10n.errorLoad),
          backgroundColor: themeConfig.secondaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                quizState.error ?? context.l10n.errorLoad,
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => context.pop(),
                child: Text(context.l10n.goBack),
              ),
            ],
          ),
        ),
      );
    }

    if (quizState.status != QuizStatus.active || quizState.questions.isEmpty) {
      return Scaffold(
        body: Center(
          child: Text(
            context.l10n.noQuestions,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      );
    }

    final currentQuestion = quizState.questions[quizState.currentQuestionIndex];
    final selectedAnswer = quizState.answers[currentQuestion.id];
    final feedback = quizState.feedback[currentQuestion.id];

    return Scaffold(
      backgroundColor: themeConfig.primaryColor,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: themeConfig.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          quizState.quizTitle ?? context.l10n.quizFallbackTitle,
          style: TextStyle(color: themeConfig.textPrimary),
        ),
        backgroundColor: themeConfig.secondaryColor,
      ),
      body: Container(
        decoration: themeConfig.backgroundImage != null && isHoliday
            ? BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(themeConfig.backgroundImage!),
                  fit: BoxFit.cover,
                  opacity: 0.3,
                ),
              )
            : null,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: QuestionCard(
              question: currentQuestion,
              currentIndex: quizState.currentQuestionIndex,
              totalQuestions: quizState.questions.length,
              selectedAnswer: selectedAnswer,
              feedback: feedback,
              stats: quizState.stats,
              onAnswer: (index) async {
                await ref
                    .read(quizStateProvider.notifier)
                    .submitAnswer(currentQuestion.id, index);

                // Auto-advance if correct
                if (feedback?.correct == true) {
                  Future.delayed(const Duration(seconds: 2), () {
                    if (mounted) {
                      final nextIndex = quizState.currentQuestionIndex + 1;
                      if (nextIndex < quizState.questions.length) {
                        ref
                            .read(quizStateProvider.notifier)
                            .selectQuestion(nextIndex);
                      }
                    }
                  });
                }
              },
              onNext: () {
                final nextIndex = quizState.currentQuestionIndex + 1;
                if (nextIndex < quizState.questions.length) {
                  ref
                      .read(quizStateProvider.notifier)
                      .selectQuestion(nextIndex);
                }
              },
              onPrevious: () {
                final prevIndex = quizState.currentQuestionIndex - 1;
                if (prevIndex >= 0) {
                  ref
                      .read(quizStateProvider.notifier)
                      .selectQuestion(prevIndex);
                }
              },
              onReset: () {
                ref.read(quizStateProvider.notifier).retryQuiz();
              },
              onShuffle: () {
                ref.read(quizStateProvider.notifier).shuffleQuestions();
              },
            ),
          ),
        ),
      ),
    );
  }
}
