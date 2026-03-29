package repository

import (
	"context"
	"testing"
	"time"

	"quiz_master/internal/models"
	storagedb "quiz_master/internal/storage/db"
)

func TestRoomStateRepositoryRoundTrip(t *testing.T) {
	database, err := storagedb.Open(context.Background(), storagedb.Config{
		Driver:       "sqlite",
		Path:         ":memory:",
		MaxOpenConns: 1,
		MaxIdleConns: 1,
		ConnMaxIdle:  time.Minute,
	})
	if err != nil {
		t.Fatalf("open db: %v", err)
	}
	defer database.Close()

	repo := NewRoomStateRepository(database)
	room := &models.Room{
		Code:    "ABCD",
		HostID:  "host",
		Players: map[string]*models.Player{"host": {Username: "host", AvatarColor: "#111111"}},
		State:   "waiting",
		Votes:   map[int]map[string]int{},
	}

	if err := repo.Create(room); err != nil {
		t.Fatalf("create room: %v", err)
	}

	loaded, err := repo.Get(room.Code)
	if err != nil {
		t.Fatalf("get room: %v", err)
	}
	if loaded == nil || loaded.Code != room.Code {
		t.Fatal("expected created room to load")
	}

	loaded.State = "playing"
	if err := repo.Update(loaded); err != nil {
		t.Fatalf("update room: %v", err)
	}

	updated, err := repo.Get(room.Code)
	if err != nil {
		t.Fatalf("reload room: %v", err)
	}
	if updated.Version <= 1 {
		t.Fatalf("expected version to increment, got %d", updated.Version)
	}
	if updated.State != "playing" {
		t.Fatalf("expected updated state, got %q", updated.State)
	}
}
