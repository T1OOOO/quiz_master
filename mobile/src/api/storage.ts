import AsyncStorage from '@react-native-async-storage/async-storage';
import { Quiz } from '../types/quiz';

const KEYS = {
    QUIZ_PREFIX: 'quiz_data_',
    SUMMARY_PREFIX: 'quiz_summary_'
};

export const Storage = {
    /**
     * Save full quiz data to cache
     */
    saveQuiz: async (id: string, data: Quiz) => {
        try {
            await AsyncStorage.setItem(`${KEYS.QUIZ_PREFIX}${id}`, JSON.stringify({
                data,
                timestamp: Date.now()
            }));
        } catch (e) {
            console.warn('Failed to cache quiz', e);
        }
    },

    /**
     * Get full quiz data from cache
     */
    getQuiz: async (id: string): Promise<Quiz | null> => {
        try {
            const json = await AsyncStorage.getItem(`${KEYS.QUIZ_PREFIX}${id}`);
            if (!json) return null;
            const parsed = JSON.parse(json);
            return parsed.data as Quiz;
        } catch (e) {
            console.warn('Failed to load quiz from cache', e);
            return null;
        }
    },

    /**
     * Save quiz summary (for lightweight listing)
     */
    saveSummary: async (id: string, data: Quiz) => {
        try {
            await AsyncStorage.setItem(`${KEYS.SUMMARY_PREFIX}${id}`, JSON.stringify({
                data,
                timestamp: Date.now()
            }));
        } catch (e) {
            console.warn('Failed to cache summary', e);
        }
    },

    /**
     * Get quiz summary from cache
     */
    getSummary: async (id: string): Promise<Quiz | null> => {
        try {
            const json = await AsyncStorage.getItem(`${KEYS.SUMMARY_PREFIX}${id}`);
            if (!json) return null;
            const parsed = JSON.parse(json);
            return parsed.data as Quiz;
        } catch (e) {
            return null;
        }
    },
    /**
     * Save individual question to cache
     */
    saveQuestion: async (quizId: string, question: any) => {
        try {
            await AsyncStorage.setItem(`${KEYS.QUIZ_PREFIX}${quizId}_q_${question.id}`, JSON.stringify({
                data: question,
                timestamp: Date.now()
            }));
        } catch (e) {
            console.warn('Failed to cache question', e);
        }
    },

    /**
     * Get individual question from cache
     */
    getQuestion: async (quizId: string, questionId: string): Promise<any | null> => {
        try {
            const json = await AsyncStorage.getItem(`${KEYS.QUIZ_PREFIX}${quizId}_q_${questionId}`);
            if (!json) return null;
            const parsed = JSON.parse(json);
            return parsed.data;
        } catch (e) {
            return null;
        }
    }
};
