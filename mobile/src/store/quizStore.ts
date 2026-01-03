import { create } from 'zustand';
import { QuizRepository } from '../api/quizRepository';
import { Question, Feedback, Quiz } from '../types/quiz';

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

// Helper to shuffle questions
function shuffleArray<T>(array: T[]): T[] {
    const shuffled = [...array];
    for (let i = shuffled.length - 1; i > 0; i--) {
        const j = Math.floor(Math.random() * (i + 1));
        [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
    }
    return shuffled;
}

// Helper to process a single question (shuffle options)
function processSingleQuestion(q: Question): Question {
    // Create an array of indices [0, 1, 2, 3]
    const indices = q.options.map((_, i) => i);
    // Shuffle the indices
    const shuffledIndices = shuffleArray(indices);
    
    // Map options to new positions
    const shuffledOptions = shuffledIndices.map(i => q.options[i]);
    
    // Store mapping to find original index later
    const mapping = shuffledIndices.map((originalIdx, currentIdx) => ({
        opt: q.options[originalIdx],
        originalIdx
    }));

    return {
        ...q,
        options: shuffledOptions,
        _optionMapping: mapping,
        _fullyLoaded: true // Marker to indicate full data is present
    };
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
    // Prevent re-fetching if already loaded
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
      // 1. Fetch Summary (Lightweight)
      const data = await QuizRepository.getSummary(id);
      const catTitle = typeof data.category === 'string' ? data.category : data.category?.title;

      set({
        status: 'active',
        quizTitle: data.title,
        quizCategory: catTitle || null,
        questions: data.questions, // Placeholders
      });

      // 2. Load First Question Immediately
      await get().loadQuestion(0);
      
      // 3. Preload next
      get().preloadQuestions(0);

    } catch (err) {
      console.error('Failed to init quiz:', err);
      // Fallback: try full load if summary fails
      try {
          const data = await QuizRepository.getById(id);
           const processed = data.questions.map(processSingleQuestion);
           set({
               status: 'active',
               quizTitle: data.title,
               questions: processed
           });
      } catch (fallbackErr) {
          set({ status: 'error', error: 'Failed to load quiz' });
      }
    }
  },

  // New Action: Load specific question data
  loadQuestion: async (index: number) => {
      const state = get();
      const question = state.questions[index];
      
      // Safety checks
      if (!question) return;
      // @ts-ignore
      if (question._fullyLoaded || (question.text && question.text.length > 0)) return; // Already loaded

      try {
          // Fetch full data
          const fullData = await QuizRepository.getQuestion(state.quizId!, question.id);
          
          // Process (shuffle)
          const processed = processSingleQuestion(fullData);

          // Update state
          set(prev => {
              const newQuestions = [...prev.questions];
              newQuestions[index] = processed;
              return { questions: newQuestions };
          });
      } catch (err) {
          console.error(`Failed to load question ${index}`, err);
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
