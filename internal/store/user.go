package store

import (
	"database/sql"

	"quiz_master/internal/models"
	storagerepo "quiz_master/internal/storage/repository"
)

type UserStore struct {
	*storagerepo.UserRepository
}

func NewUserStore(db *sql.DB) *UserStore {
	return &UserStore{UserRepository: storagerepo.NewUserRepository(db)}
}

func (r *UserStore) GetByUsername(username string) (*models.User, error) {
	return r.UserRepository.GetByUsername(username)
}
