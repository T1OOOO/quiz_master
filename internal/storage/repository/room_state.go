package repository

import (
	"database/sql"
	"encoding/json"
	"errors"

	"quiz_master/internal/dbx"
	"quiz_master/internal/models"
)

type RoomStateRepository struct {
	db *sql.DB
}

func NewRoomStateRepository(db *sql.DB) *RoomStateRepository {
	return &RoomStateRepository{db: db}
}

func (r *RoomStateRepository) Create(room *models.Room) error {
	if room == nil {
		return errors.New("room is nil")
	}
	payload, err := json.Marshal(room)
	if err != nil {
		return err
	}
	room.Version = 1
	_, err = r.db.Exec(
		dbx.Rebind(r.db, "INSERT INTO rooms_state (code, state_json, version, updated_at) VALUES (?, ?, ?, "+dbx.NowExpr(r.db)+")"),
		room.Code,
		string(payload),
		room.Version,
	)
	return err
}

func (r *RoomStateRepository) Get(code string) (*models.Room, error) {
	var (
		payload string
		version int64
	)
	err := r.db.QueryRow(
		dbx.Rebind(r.db, "SELECT state_json, version FROM rooms_state WHERE code = ?"),
		code,
	).Scan(&payload, &version)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}

	var room models.Room
	if err := json.Unmarshal([]byte(payload), &room); err != nil {
		return nil, err
	}
	room.Version = version
	if room.Players == nil {
		room.Players = map[string]*models.Player{}
	}
	if room.Votes == nil {
		room.Votes = map[int]map[string]int{}
	}
	if room.Revealed == nil {
		room.Revealed = map[int]bool{}
	}
	return &room, nil
}

func (r *RoomStateRepository) Update(room *models.Room) error {
	if room == nil {
		return errors.New("room is nil")
	}
	room.Version++
	payload, err := json.Marshal(room)
	if err != nil {
		return err
	}
	_, err = r.db.Exec(
		dbx.Rebind(r.db, "UPDATE rooms_state SET state_json = ?, version = ?, updated_at = "+dbx.NowExpr(r.db)+" WHERE code = ?"),
		string(payload),
		room.Version,
		room.Code,
	)
	return err
}

func (r *RoomStateRepository) Delete(code string) error {
	_, err := r.db.Exec(dbx.Rebind(r.db, "DELETE FROM rooms_state WHERE code = ?"), code)
	return err
}
