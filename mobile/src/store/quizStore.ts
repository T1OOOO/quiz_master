import { create } from 'zustand';
import { QuizRepository } from '../api/quizRepository';
import { Storage } from '../api/storage';
import { Question, Feedback, Quiz } from '../types/quiz';
import { processSingleQuestion, shuffleArray } from '../utils/quizEngine';

interface QuizState {
  // State
  quizId: string | null;
  status: 'idle' | 'loading' | 'active' | 'completed' | 'error';
  error: string | null;
  quizTitle: string | null;
  quizCategory: string | null; // Added category
  questions: Question[];
  currentQuestionIndex: number;
  answers: Record<string, number>; // questionId -> answerIndex
  feedback: Record<string, Feedback>; // questionId -> Feedback
  startTime: number | null;

  // Actions
  initQuiz: (id: string) => Promise<void>;
  selectQuestion: (index: number) => void;
  submitAnswer: (questionId: string, answerIndex: number) => Promise<void>;
  resetQuiz: () => void;
  retryQuiz: () => void;
  shuffleQuestions: () => void;
  loadQuestion: (index: number) => Promise<void>;
  preloadQuestions: (currentIndex: number) => void;
}

export const useQuizStore = create<QuizState>((set, get) => ({
  // Initial State
  quizId: null,
  status: 'idle',
  error: null,
  quizTitle: null,
  quizCategory: null,
  questions: [],
  currentQuestionIndex: 0,
  answers: {},
  feedback: {},
  startTime: null,

  // Actions
  initQuiz: async (id: string) => {
    if (get().quizId === id && get().status === 'active') return;

    set({ 
      status: 'loading', 
      error: null, 
      quizId: id,
      answers: {},
      feedback: {},
      currentQuestionIndex: 0,
      startTime: Date.now(),
      questions: []
    });

    try {
      // 1. Try Network
      const data = await QuizRepository.getSummary(id);
      
      // Cache it
      Storage.saveSummary(id, data);

      const catTitle = typeof data.category === 'string' ? data.category : data.category?.title;

      set({
        status: 'active',
        quizTitle: data.title,
        quizCategory: catTitle || null,
        questions: data.questions,
      });

      await get().loadQuestion(0);
      get().preloadQuestions(0);

    } catch (err) {
      console.warn('Network init failed, trying cache...', err);
      
      // 2. Try Cache
      const cached = await Storage.getSummary(id);
      if (cached) {
          const catTitle = typeof cached.category === 'string' ? cached.category : cached.category?.title;
          set({
              status: 'active',
              quizTitle: cached.title,
              quizCategory: catTitle || null,
              questions: cached.questions,
          });
          // Try loading first question from cache
          await get().loadQuestion(0);
      } else {
          set({ status: 'error', error: 'Failed to load quiz (Offline)' });
      }
    }
  },

  // New Action: Load specific question data
  loadQuestion: async (index: number) => {
      const state = get();
      const question = state.questions[index];
      
      if (!question) return;
      // @ts-ignore
      if (question._fullyLoaded) return; 

      try {
          // 1. Network
          const fullData = await QuizRepository.getQuestion(state.quizId!, question.id);
          
          // Cache it
          Storage.saveQuestion(state.quizId!, fullData);

          const processed = processSingleQuestion(fullData);

          set(prev => {
              const newQuestions = [...prev.questions];
              newQuestions[index] = processed;
              return { questions: newQuestions };
          });
      } catch (err) {
          console.warn(`Network load question ${index} failed, trying cache...`);
          
          // 2. Cache
          const cached = await Storage.getQuestion(state.quizId!, question.id);
          if (cached) {
              const processed = processSingleQuestion(cached);
              set(prev => {
                  const newQuestions = [...prev.questions];
                  newQuestions[index] = processed;
                  return { questions: newQuestions };
              });
          }
      }
  },

  preloadQuestions: (currentIndex: number) => {
      const state = get();
      // Preload Next 2
      const next1 = currentIndex + 1;
      const next2 = currentIndex + 2;
      
      if (next1 < state.questions.length) state.loadQuestion(next1);
      if (next2 < state.questions.length) state.loadQuestion(next2);
  },

  selectQuestion: (index: number) => {
    const { questions } = get();
    if (index >= 0 && index < questions.length) {
      set({ currentQuestionIndex: index });
      // Ensure the selected question itself is loaded
      get().loadQuestion(index);
      // Trigger preload for upcoming
      get().preloadQuestions(index);
    }
  },

  submitAnswer: async (questionId: string, answerIndex: number) => {
    const { questions, answers, feedback } = get();
    
    // Prevent re-answering
    if (answers[questionId] !== undefined) return;

    const question = questions.find(q => q.id === questionId);
    if (!question) return;

    // Find original index if options were shuffled
    let originalAnswerIndex = answerIndex;
    if (question._optionMapping) {
        originalAnswerIndex = question._optionMapping[answerIndex].originalIdx;
    }

    try {
        const result = await QuizRepository.checkAnswer(get().quizId!, questionId, originalAnswerIndex);
        
        set((state) => ({
            answers: { ...state.answers, [questionId]: answerIndex }, // Store VISUAL index
            feedback: { ...state.feedback, [questionId]: result }
        }));
    } catch (err) {
        console.error('Submit answer error:', err);
    }
  },

  resetQuiz: () => {
    set({
      quizId: null,
      status: 'idle',
      questions: [],
      currentQuestionIndex: 0,
      answers: {},
      feedback: {},
      error: null
    });
  },

  retryQuiz: () => {
    set({
      answers: {},
      feedback: {},
      currentQuestionIndex: 0,
      startTime: Date.now()
    });
    // Trigger preload again just in case
    get().preloadQuestions(0);
  },

  shuffleQuestions: () => {
      set((state) => ({
          // We only shuffle the array order, but keep individual question data
          questions: shuffleArray(state.questions),
          currentQuestionIndex: 0,
          answers: {},
          feedback: {}
      }));
      // Retrigger preload for new order
      get().preloadQuestions(0);
  }
}));
