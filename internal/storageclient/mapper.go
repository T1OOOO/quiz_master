package storageclient

import (
	quizdomain "quiz_master/internal/quiz/domain"
	storagedto "quiz_master/internal/storageapi/dto"
)

func toDomainQuestion(q storagedto.Question) quizdomain.Question {
	return quizdomain.Question{
		ID:                 q.ID,
		Type:               q.Type,
		Text:               q.Text,
		ImageURL:           q.ImageURL,
		Options:            q.Options,
		CorrectAnswerIndex: q.CorrectAnswerIndex,
		CorrectText:        q.CorrectText,
		CorrectMulti:       q.CorrectMulti,
		Explanation:        q.Explanation,
		Difficulty:         q.Difficulty,
	}
}

func toDomainQuiz(q *storagedto.Quiz) *quizdomain.Quiz {
	if q == nil {
		return nil
	}

	out := &quizdomain.Quiz{
		ID:             q.ID,
		Title:          q.Title,
		Description:    q.Description,
		Category:       q.Category,
		QuestionsCount: q.QuestionsCount,
	}
	if len(q.Questions) > 0 {
		out.Questions = make([]quizdomain.Question, len(q.Questions))
		for i, question := range q.Questions {
			out.Questions[i] = toDomainQuestion(question)
		}
	}

	return out
}

func toDTOQuestion(q quizdomain.Question) storagedto.Question {
	return storagedto.Question{
		ID:                 q.ID,
		Type:               q.Type,
		Text:               q.Text,
		ImageURL:           q.ImageURL,
		Options:            q.Options,
		CorrectAnswerIndex: q.CorrectAnswerIndex,
		CorrectText:        q.CorrectText,
		CorrectMulti:       q.CorrectMulti,
		Explanation:        q.Explanation,
		Difficulty:         q.Difficulty,
	}
}

func toDTOQuiz(q *quizdomain.Quiz) *storagedto.Quiz {
	if q == nil {
		return nil
	}

	out := &storagedto.Quiz{
		ID:             q.ID,
		Title:          q.Title,
		Description:    q.Description,
		Category:       q.Category,
		QuestionsCount: q.QuestionsCount,
	}
	if len(q.Questions) > 0 {
		out.Questions = make([]storagedto.Question, len(q.Questions))
		for i, question := range q.Questions {
			out.Questions[i] = toDTOQuestion(question)
		}
	}

	return out
}
