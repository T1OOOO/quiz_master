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

// Helper to process questions (shuffle options)
function processQuestions(questions: Question[]): Question[] {
    return questions.map(q => {
        // Create an array of indices [0, 1, 2, 3]
        const indices = q.options.map((_, i) => i);
        // Shuffle the indices
        const shuffledIndices = shuffleArray(indices);
        
        // Map options to new positions
        const shuffledOptions = shuffledIndices.map(i => q.options[i]);
        
        // Store mapping to find original index later
        // If correct ans is at index 0, and 0 moved to pos 2, 
        // we need to know that option at pos 2 maps to original index 0
        const mapping = shuffledIndices.map((originalIdx, currentIdx) => ({
            opt: q.options[originalIdx],
            originalIdx
        }));

        return {
            ...q,
            options: shuffledOptions,
            _optionMapping: mapping
        };
    });
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
      startTime: Date.now()
    });

    try {
      const data = await QuizRepository.getById(id);
      
      // Process questions (shuffle options) if needed
      // Note: useQuiz.ts was shuffling options. We should replicate that.
      const processedQuestions = processQuestions(data.questions);

      const catTitle = typeof data.category === 'string' ? data.category : data.category?.title;

      set({
        status: 'active',
        quizTitle: data.title,
        quizCategory: catTitle || null, // Extract category title
        questions: processedQuestions,
      });
    } catch (err) {
      console.error('Failed to init quiz:', err);
      set({ status: 'error', error: 'Failed to load quiz' });
    }
  },

  selectQuestion: (index: number) => {
    const { questions } = get();
    if (index >= 0 && index < questions.length) {
      set({ currentQuestionIndex: index });
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
  },

  shuffleQuestions: () => {
      set((state) => ({
          questions: shuffleArray(state.questions),
          currentQuestionIndex: 0,
          answers: {},
          feedback: {}
      }));
  }
}));
