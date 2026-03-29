package roomstate

import (
	"testing"

	"quiz_master/internal/models"
)

type memoryRepo struct {
	rooms map[string]*models.Room
}

func (r *memoryRepo) Create(room *models.Room) error {
	if r.rooms == nil {
		r.rooms = map[string]*models.Room{}
	}
	clone := *room
	r.rooms[room.Code] = &clone
	return nil
}

func (r *memoryRepo) Get(code string) (*models.Room, error) {
	if room, ok := r.rooms[code]; ok {
		clone := *room
		return &clone, nil
	}
	return nil, nil
}

func (r *memoryRepo) Update(room *models.Room) error {
	clone := *room
	r.rooms[room.Code] = &clone
	return nil
}

func (r *memoryRepo) Delete(code string) error {
	delete(r.rooms, code)
	return nil
}

func TestServiceCreateJoinLeaveRoom(t *testing.T) {
	svc := New(&memoryRepo{rooms: map[string]*models.Room{}})

	room, err := svc.CreateRoom("host", "#111111")
	if err != nil {
		t.Fatalf("create room: %v", err)
	}
	if room.HostID != "host" {
		t.Fatalf("expected host to be room host, got %q", room.HostID)
	}

	room, err = svc.JoinRoom(room.Code, "guest", "#222222")
	if err != nil {
		t.Fatalf("join room: %v", err)
	}
	if len(room.Players) != 2 {
		t.Fatalf("expected 2 players, got %d", len(room.Players))
	}

	room, err = svc.LeaveRoom(room.Code, "host")
	if err != nil {
		t.Fatalf("leave room: %v", err)
	}
	if room == nil {
		t.Fatal("expected room to persist after one player leaves")
	}
	if room.HostID != "guest" {
		t.Fatalf("expected host reassignment to guest, got %q", room.HostID)
	}
}
