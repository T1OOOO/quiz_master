package quiz

import (
	"database/sql"
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/google/uuid"
	"gopkg.in/yaml.v3"
)

type Service struct {
	db *sql.DB
}

func NewService(db *sql.DB) *Service {
	return &Service{db: db}
}

// SyncFromFiles reads YAML files and populates DB if empty
func (s *Service) SyncFromFiles(dir string) error {
	var count int
	err := s.db.QueryRow("SELECT COUNT(*) FROM quizzes").Scan(&count)
	if err != nil {
		return err
	}

	if count > 0 {
		return nil // Already seeded
	}

	entries, err := os.ReadDir(dir)
	if err != nil {
		return fmt.Errorf("failed to read directory: %w", err)
	}

	for _, entry := range entries {
		if entry.IsDir() || !strings.HasSuffix(entry.Name(), ".yaml") {
			continue
		}

		path := filepath.Join(dir, entry.Name())
		data, err := os.ReadFile(path)
		if err != nil {
			return fmt.Errorf("failed to read file %s: %w", entry.Name(), err)
		}

		var q Quiz
		if err := yaml.Unmarshal(data, &q); err != nil {
			return fmt.Errorf("failed to parse yaml %s: %w", entry.Name(), err)
		}

		if q.ID == "" {
			q.ID = strings.TrimSuffix(entry.Name(), ".yaml")
		}

		if err := s.Create(&q); err != nil {
			return fmt.Errorf("failed to import quiz %s: %w", q.ID, err)
		}
	}
	return nil
}

func (s *Service) List() ([]Quiz, error) {
	rows, err := s.db.Query("SELECT id, title, description FROM quizzes")
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var quizzes []Quiz
	for rows.Next() {
		var q Quiz
		if err := rows.Scan(&q.ID, &q.Title, &q.Description); err != nil {
			continue
		}
		// We could fetch questions count specifically if needed
		quizzes = append(quizzes, q)
	}
	return quizzes, nil
}

func (s *Service) Get(id string) (*Quiz, error) {
	var q Quiz
	err := s.db.QueryRow("SELECT id, title, description FROM quizzes WHERE id = ?", id).
		Scan(&q.ID, &q.Title, &q.Description)
	if err == sql.ErrNoRows {
		return nil, nil // Not found
	} else if err != nil {
		return nil, err
	}

	rows, err := s.db.Query("SELECT id, text, options, correct_answer_index, type FROM questions WHERE quiz_id = ?", id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var quest Question
		var optionsJSON string
		if err := rows.Scan(&quest.ID, &quest.Text, &optionsJSON, &quest.CorrectAnswerIndex, &quest.Type); err != nil {
			continue
		}
		json.Unmarshal([]byte(optionsJSON), &quest.Options)
		q.Questions = append(q.Questions, quest)
	}

	return &q, nil
}

func (s *Service) Create(q *Quiz) error {
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}

	if q.ID == "" {
		q.ID = uuid.New().String()
	}

	_, err = tx.Exec("INSERT INTO quizzes (id, title, description) VALUES (?, ?, ?)", q.ID, q.Title, q.Description)
	if err != nil {
		tx.Rollback()
		return err
	}

	for _, quest := range q.Questions {
		if quest.ID == "" {
			quest.ID = uuid.New().String()
		}
		if quest.Type == "" {
			quest.Type = "choice"
		}
		optionsJSON, _ := json.Marshal(quest.Options)
		_, err = tx.Exec("INSERT INTO questions (id, quiz_id, text, options, correct_answer_index, type) VALUES (?, ?, ?, ?, ?, ?)",
			quest.ID, q.ID, quest.Text, string(optionsJSON), quest.CorrectAnswerIndex, quest.Type)
		if err != nil {
			tx.Rollback()
			return err
		}
	}

	return tx.Commit()
}

func (s *Service) Delete(id string) error {
	_, err := s.db.Exec("DELETE FROM quizzes WHERE id = ?", id)
	return err
}

func (s *Service) CheckAnswer(quizID, questionID string, answerIdx int) (*AnswerResult, bool) {
	// For simplicity, we can reuse Get or write specific query
	// Ideally we cache this or use a specific query
	var correctIdx int
	err := s.db.QueryRow("SELECT correct_answer_index FROM questions WHERE id = ? AND quiz_id = ?", questionID, quizID).Scan(&correctIdx)
	if err != nil {
		return nil, false
	}

	correct := correctIdx == answerIdx
	return &AnswerResult{
		Correct:       correct,
		CorrectAnswer: correctIdx, // In a real app we might hide this if checks are done per question
	}, true
}

func (s *Service) Update(q *Quiz) error {
	tx, err := s.db.Begin()
	if err != nil {
		return err
	}

	// Update main quiz details
	_, err = tx.Exec("UPDATE quizzes SET title = ?, description = ? WHERE id = ?", q.Title, q.Description, q.ID)
	if err != nil {
		tx.Rollback()
		return err
	}

	// For simplicity in this architecture: Delete all questions and re-insert
	_, err = tx.Exec("DELETE FROM questions WHERE quiz_id = ?", q.ID)
	if err != nil {
		tx.Rollback()
		return err
	}

	for _, quest := range q.Questions {
		if quest.ID == "" {
			quest.ID = uuid.New().String()
		}
		if quest.Type == "" {
			quest.Type = "choice"
		}
		optionsJSON, _ := json.Marshal(quest.Options)
		multiJSON, _ := json.Marshal(quest.CorrectMulti)
		_, err = tx.Exec("INSERT INTO questions (id, quiz_id, type, text, options, correct_answer_index, correct_text, correct_multi, image_url, explanation, difficulty) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)",
			quest.ID, q.ID, quest.Type, quest.Text, string(optionsJSON), quest.CorrectAnswerIndex, quest.CorrectText, string(multiJSON), quest.ImageURL, quest.Explanation, quest.Difficulty)
		if err != nil {
			tx.Rollback()
			return err
		}
	}

	return tx.Commit()
}
