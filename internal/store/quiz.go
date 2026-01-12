package store

import (
	"database/sql"
	"encoding/json"
	"iter"
	"quiz_master/internal/models"

	"github.com/google/uuid"
)

type QuizStore struct {
	db *sql.DB
}

func NewQuizStore(db *sql.DB) *QuizStore {
	return &QuizStore{db: db}
}

func (r *QuizStore) List() ([]models.Quiz, error) {
	var quizzes []models.Quiz
	for q, err := range r.All() {
		if err != nil {
			return nil, err
		}
		quizzes = append(quizzes, q)
	}
	return quizzes, nil
}

func (r *QuizStore) All() iter.Seq2[models.Quiz, error] {
	return func(yield func(models.Quiz, error) bool) {
		// Include subquery to count questions
		rows, err := r.db.Query(`
			SELECT 
				q.id, q.title, q.description, q.category,
				(SELECT COUNT(*) FROM questions WHERE quiz_id = q.id) as q_count
			FROM quizzes q
		`)
		if err != nil {
			yield(models.Quiz{}, err)
			return
		}
		defer rows.Close()

		for rows.Next() {
			var q models.Quiz
			if err := rows.Scan(&q.ID, &q.Title, &q.Description, &q.Category, &q.QuestionsCount); err != nil {
				if !yield(models.Quiz{}, err) {
					return
				}
				continue
			}
			if !yield(q, nil) {
				return
			}
		}
	}
}

func (r *QuizStore) Get(id string) (*models.Quiz, error) {
	var q models.Quiz
	err := r.db.QueryRow("SELECT id, title, description, category FROM quizzes WHERE id = ?", id).
		Scan(&q.ID, &q.Title, &q.Description, &q.Category)
	if err == sql.ErrNoRows {
		return nil, nil
	} else if err != nil {
		return nil, err
	}

	rows, err := r.db.Query("SELECT id, type, text, options, correct_answer_index, correct_text, correct_multi, image_url, explanation, difficulty FROM questions WHERE quiz_id = ?", id)

	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var quest models.Question
		var optionsJSON string
		var correctText sql.NullString
		var multiJSON sql.NullString
		var imageUrl sql.NullString
		var explanation sql.NullString
		var difficulty sql.NullInt64
		if err := rows.Scan(&quest.ID, &quest.Type, &quest.Text, &optionsJSON, &quest.CorrectAnswerIndex, &correctText, &multiJSON, &imageUrl, &explanation, &difficulty); err != nil {
			return nil, err
		}
		json.Unmarshal([]byte(optionsJSON), &quest.Options)
		quest.CorrectText = correctText.String
		quest.ImageURL = imageUrl.String
		quest.Explanation = explanation.String
		if difficulty.Valid {
			quest.Difficulty = int(difficulty.Int64)
		}
		if multiJSON.Valid {
			json.Unmarshal([]byte(multiJSON.String), &quest.CorrectMulti)
		}
		q.Questions = append(q.Questions, quest)
	}

	return &q, nil
}

// GetSummary returns the quiz with lightweight question metadata (ID, Type, Difficulty) only.
func (r *QuizStore) GetSummary(id string) (*models.Quiz, error) {
	var q models.Quiz
	err := r.db.QueryRow("SELECT id, title, description, category FROM quizzes WHERE id = ?", id).
		Scan(&q.ID, &q.Title, &q.Description, &q.Category)
	if err == sql.ErrNoRows {
		return nil, nil
	} else if err != nil {
		return nil, err
	}

	// Only fetch essential metadata for questions: ID, Type, Difficulty
	// We sort by rowid (implicitly insertion order) or add an order column? For now, we assume implicit order.
	// Fetch metadata + Text for sidebar
	rows, err := r.db.Query("SELECT id, type, difficulty, text FROM questions WHERE quiz_id = ?", id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var quest models.Question
		var difficulty sql.NullInt64
		if err := rows.Scan(&quest.ID, &quest.Type, &difficulty, &quest.Text); err != nil {
			return nil, err
		}
		if difficulty.Valid {
			quest.Difficulty = int(difficulty.Int64)
		}
		// Optimize payload: omit heavy fields not needed for sidebar
		quest.Options = nil
		quest.ImageURL = ""
		quest.Explanation = ""

		q.Questions = append(q.Questions, quest)
	}
	return &q, nil
}

// GetQuestion returns a single full question by ID.
func (r *QuizStore) GetQuestion(quizID, questionID string) (*models.Question, error) {
	var quest models.Question
	var optionsJSON string
	var correctText sql.NullString
	var multiJSON sql.NullString
	var imageUrl sql.NullString
	var explanation sql.NullString
	var difficulty sql.NullInt64

	row := r.db.QueryRow(`
		SELECT id, type, text, options, correct_answer_index, correct_text, correct_multi, image_url, explanation, difficulty 
		FROM questions 
		WHERE quiz_id = ? AND id = ?`, quizID, questionID)

	err := row.Scan(&quest.ID, &quest.Type, &quest.Text, &optionsJSON, &quest.CorrectAnswerIndex, &correctText, &multiJSON, &imageUrl, &explanation, &difficulty)
	if err == sql.ErrNoRows {
		return nil, nil
	} else if err != nil {
		return nil, err
	}

	json.Unmarshal([]byte(optionsJSON), &quest.Options)
	quest.CorrectText = correctText.String
	quest.ImageURL = imageUrl.String
	quest.Explanation = explanation.String
	if difficulty.Valid {
		quest.Difficulty = int(difficulty.Int64)
	}
	if multiJSON.Valid {
		json.Unmarshal([]byte(multiJSON.String), &quest.CorrectMulti)
	}

	return &quest, nil
}

func (r *QuizStore) Create(q *models.Quiz) error {
	tx, err := r.db.Begin()
	if err != nil {
		return err
	}

	if q.ID == "" {
		q.ID = uuid.New().String()
	}

	if q.Category == "" {
		q.Category = "Разное"
	}

	_, err = tx.Exec("INSERT INTO quizzes (id, title, description, category) VALUES (?, ?, ?, ?)", q.ID, q.Title, q.Description, q.Category)
	if err != nil {
		tx.Rollback()
		return err
	}

	for _, quest := range q.Questions {
		// Always generate unique question IDs to avoid YAML conflicts
		quest.ID = uuid.New().String()

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

func (r *QuizStore) Update(q *models.Quiz) error {
	tx, err := r.db.Begin()
	if err != nil {
		return err
	}

	if q.Category == "" {
		q.Category = "Разное"
	}

	_, err = tx.Exec("UPDATE quizzes SET title = ?, description = ?, category = ? WHERE id = ?", q.Title, q.Description, q.Category, q.ID)
	if err != nil {
		tx.Rollback()
		return err
	}

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

func (r *QuizStore) Delete(id string) error {
	_, err := r.db.Exec("DELETE FROM quizzes WHERE id = ?", id)
	return err
}
