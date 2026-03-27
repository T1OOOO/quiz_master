import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quiz_master/core/providers/core_providers.dart';
import 'package:quiz_master/features/quiz/domain/entities/quiz_entities.dart';
import 'package:quiz_master/features/quiz/domain/repositories/quiz_repository.dart';

final quizStateProvider = NotifierProvider<QuizStateNotifier, QuizState>(
  QuizStateNotifier.new,
);

class QuizState {
  final String? quizId;
  final QuizStatus status;
  final String? error;
  final String? quizTitle;
  final String? quizCategory;
  final List<Question> questions;
  final int currentQuestionIndex;
  final Map<String, int> answers;
  final Map<String, Feedback> feedback;
  final DateTime? startTime;

  QuizState({
    this.quizId,
    this.status = QuizStatus.idle,
    this.error,
    this.quizTitle,
    this.quizCategory,
    this.questions = const [],
    this.currentQuestionIndex = 0,
    this.answers = const {},
    this.feedback = const {},
    this.startTime,
  });

  QuizState copyWith({
    String? quizId,
    QuizStatus? status,
    String? error,
    String? quizTitle,
    String? quizCategory,
    List<Question>? questions,
    int? currentQuestionIndex,
    Map<String, int>? answers,
    Map<String, Feedback>? feedback,
    DateTime? startTime,
  }) {
    return QuizState(
      quizId: quizId ?? this.quizId,
      status: status ?? this.status,
      error: error ?? this.error,
      quizTitle: quizTitle ?? this.quizTitle,
      quizCategory: quizCategory ?? this.quizCategory,
      questions: questions ?? this.questions,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      answers: answers ?? this.answers,
      feedback: feedback ?? this.feedback,
      startTime: startTime ?? this.startTime,
    );
  }

  QuizStats get stats {
    int correct = 0;
    int incorrect = 0;
    for (final f in feedback.values) {
      if (f.correct) {
        correct++;
      } else {
        incorrect++;
      }
    }
    return QuizStats(
      correct: correct,
      incorrect: incorrect,
      answered: correct + incorrect,
      total: questions.length,
    );
  }
}

enum QuizStatus { idle, loading, active, completed, error }

class QuizStateNotifier extends Notifier<QuizState> {
  late final QuizRepository _repository;

  @override
  QuizState build() {
    _repository = ref.watch(quizRepositoryProvider);
    return QuizState(
      quizId: null,
      status: QuizStatus.idle,
      error: null,
      quizTitle: null,
      quizCategory: null,
      questions: const [],
      currentQuestionIndex: 0,
      answers: const {},
      feedback: const {},
      startTime: null,
    );
  }

  Future<void> initQuiz(String id) async {
    if (state.quizId == id && state.status == QuizStatus.active) return;

    state = state.copyWith(
      status: QuizStatus.loading,
      error: null,
      quizId: id,
      answers: {},
      feedback: {},
      currentQuestionIndex: 0,
      startTime: DateTime.now(),
      questions: [],
    );

    try {
      final data = await _repository.getQuizSummary(id);
      final catTitle = data.categoryString ?? data.category?.title;

      state = state.copyWith(
        status: QuizStatus.active,
        quizTitle: data.title,
        quizCategory: catTitle,
        questions: data.questions,
      );

      await loadQuestion(0);
    } catch (e) {
      state = state.copyWith(
        status: QuizStatus.error,
        error: 'Failed to load quiz: ${e.toString()}',
      );
    }
  }

  Future<void> loadQuestion(int index) async {
    if (index < 0 || index >= state.questions.length) return;

    final question = state.questions[index];
    if (question.fullyLoaded) return;

    try {
      final loadedQuestion = await _repository.getQuestion(
        state.quizId!,
        question.id,
      );
      final updatedQuestions = List<Question>.from(state.questions);
      updatedQuestions[index] = loadedQuestion.copyWith(fullyLoaded: true);
      state = state.copyWith(questions: updatedQuestions);
    } catch (e) {
      // Continue with existing question if load fails
    }
  }

  void selectQuestion(int index) {
    if (index >= 0 && index < state.questions.length) {
      state = state.copyWith(currentQuestionIndex: index);
      loadQuestion(index);
    }
  }

  Future<void> submitAnswer(String questionId, int answerIndex) async {
    if (state.answers.containsKey(questionId)) return;

    final updatedAnswers = Map<String, int>.from(state.answers);
    updatedAnswers[questionId] = answerIndex;
    state = state.copyWith(answers: updatedAnswers);

    try {
      final feedback = await _repository.checkAnswer(
        state.quizId!,
        questionId,
        answerIndex,
      );
      final updatedFeedback = Map<String, Feedback>.from(state.feedback);
      updatedFeedback[questionId] = feedback;
      state = state.copyWith(feedback: updatedFeedback);
    } catch (e) {
      // Handle error
    }
  }

  void resetQuiz() {
    state = QuizState();
  }

  void retryQuiz() {
    if (state.quizId != null) {
      initQuiz(state.quizId!);
    }
  }

  void shuffleQuestions() {
    final shuffled = List<Question>.from(state.questions)..shuffle();
    state = state.copyWith(questions: shuffled, currentQuestionIndex: 0);
  }
}
