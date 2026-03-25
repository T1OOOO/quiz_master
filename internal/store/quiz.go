package store

import (
	"database/sql"

	storagerepo "quiz_master/internal/storage/repository"
)

type QuizStore struct {
	*storagerepo.QuizRepository
}

func NewQuizStore(db *sql.DB) *QuizStore {
	return &QuizStore{QuizRepository: storagerepo.NewQuizRepository(db)}
}
