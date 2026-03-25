package store

import (
	"context"
	"database/sql"
	"time"

	storagedb "quiz_master/internal/storage/db"
)

var DB *sql.DB

func InitDB(filepath string) error {
	db, err := storagedb.Open(context.Background(), storagedb.Config{
		Path:         filepath,
		MaxOpenConns: 1,
		MaxIdleConns: 1,
		ConnMaxIdle:  5 * time.Minute,
	})
	if err != nil {
		return err
	}
	DB = db
	return nil
}
