package api

import (
	quizhttp "quiz_master/internal/quiz/http"
	quizservice "quiz_master/internal/quiz/service"
)

type QuizHandler = quizhttp.Handler

func NewQuizHandler(s *quizservice.QuizService) *QuizHandler {
	return quizhttp.NewHandler(s)
}
