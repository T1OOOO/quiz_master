import axios from './axios';
import { Quiz, Feedback } from '../types/quiz';

export const QuizRepository = {
    /**
     * Fetch all quizzes from the API
     */
    async getAll(): Promise<Quiz[]> {
        const response = await axios.get('/api/quizzes');
        return response.data;
    },

    /**
     * Fetch a single quiz by its ID or slug
     */
    async getById(id: string): Promise<Quiz> {
        const response = await axios.get(`/api/quizzes/${id}`);
        return response.data;
    },

    /**
     * Validate an answer for a specific question
     */
    async checkAnswer(quizId: string, questionId: string, answerIndex: number): Promise<Feedback> {
        const response = await axios.post(`/api/quizzes/${quizId}/check`, {
            quiz_id: quizId,
            question_id: questionId,
            answer: answerIndex
        });
        return response.data;
    },

    /**
     * Submit the final score to the leaderboard
     */
    async submitScore(quizId: string, score: number, total: number, token?: string): Promise<boolean> {
        if (!token) return false;
        try {
            await axios.post('/api/submit', {
                quiz_id: quizId,
                score: score,
                total_questions: total
            }, {
                headers: { Authorization: `Bearer ${token}` }
            });
            return true;
        } catch (error) {
            console.error('Failed to submit score:', error);
            return false;
        }
    }
};
