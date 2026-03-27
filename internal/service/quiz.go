package service

import quizservice "quiz_master/internal/quiz/service"

type QuizRepository = quizservice.QuizRepository
type QuizService = quizservice.QuizService

func NewQuizService(repo QuizRepository) *QuizService {
	return quizservice.New(repo)
}
