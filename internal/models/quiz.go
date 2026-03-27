package models

import (
	quizdomain "quiz_master/internal/quiz/domain"
	quizdto "quiz_master/internal/quiz/http/dto"
)

type Question = quizdomain.Question
type Quiz = quizdomain.Quiz
type QuizReport = quizdomain.QuizReport

type QuestionPublic = quizdto.QuestionPublic
type QuizPublic = quizdto.QuizPublic
type AnswerResult = quizdto.AnswerResult
type AnswerAttempt = quizdto.AnswerAttempt
