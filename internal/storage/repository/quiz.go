package repository

import (
	"database/sql"
	"encoding/json"
	"iter"
	"time"

	"quiz_master/internal/dbx"
	quizdomain "quiz_master/internal/quiz/domain"

	"github.com/google/uuid"
)

type QuizRepository struct {
	db *sql.DB
}

func NewQuizRepository(db *sql.DB) *QuizRepository {
	return &QuizRepository{db: db}
}

func (r *QuizRepository) List() ([]quizdomain.Quiz, error) {
	var quizzes []quizdomain.Quiz
	for q, err := range r.All() {
		if err != nil {
			return nil, err
		}
		quizzes = append(quizzes, q)
	}
	return quizzes, nil
}

func (r *QuizRepository) All() iter.Seq2[quizdomain.Quiz, error] {
	return func(yield func(quizdomain.Quiz, error) bool) {
		rows, err := r.db.Query(`
			SELECT
				q.id, q.title, q.description, q.category,
				(SELECT COUNT(*) FROM questions WHERE quiz_id = q.id) as q_count
			FROM quizzes q
		`)
		if err != nil {
			yield(quizdomain.Quiz{}, err)
			return
		}
		defer rows.Close()

		for rows.Next() {
			var q quizdomain.Quiz
			if err := rows.Scan(&q.ID, &q.Title, &q.Description, &q.Category, &q.QuestionsCount); err != nil {
				if !yield(quizdomain.Quiz{}, err) {
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

func (r *QuizRepository) Get(id string) (*quizdomain.Quiz, error) {
	var q quizdomain.Quiz
	err := r.db.QueryRow(dbx.Rebind(r.db, "SELECT id, title, description, category FROM quizzes WHERE id = ?"), id).
		Scan(&q.ID, &q.Title, &q.Description, &q.Category)
	if err == sql.ErrNoRows {
		return nil, nil
	} else if err != nil {
		return nil, err
	}

	rows, err := r.db.Query(dbx.Rebind(r.db, "SELECT id, type, text, options, correct_answer_index, correct_text, correct_multi, image_url, explanation, difficulty FROM questions WHERE quiz_id = ?"), id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var quest quizdomain.Question
		var optionsJSON string
		var correctText sql.NullString
		var multiJSON sql.NullString
		var imageURL sql.NullString
		var explanation sql.NullString
		var difficulty sql.NullInt64
		if err := rows.Scan(&quest.ID, &quest.Type, &quest.Text, &optionsJSON, &quest.CorrectAnswerIndex, &correctText, &multiJSON, &imageURL, &explanation, &difficulty); err != nil {
			return nil, err
		}
		_ = json.Unmarshal([]byte(optionsJSON), &quest.Options)
		quest.CorrectText = correctText.String
		quest.ImageURL = imageURL.String
		quest.Explanation = explanation.String
		if difficulty.Valid {
			quest.Difficulty = int(difficulty.Int64)
		}
		if multiJSON.Valid {
			_ = json.Unmarshal([]byte(multiJSON.String), &quest.CorrectMulti)
		}
		q.Questions = append(q.Questions, quest)
	}

	return &q, nil
}

func (r *QuizRepository) GetSummary(id string) (*quizdomain.Quiz, error) {
	var q quizdomain.Quiz
	err := r.db.QueryRow(dbx.Rebind(r.db, "SELECT id, title, description, category FROM quizzes WHERE id = ?"), id).
		Scan(&q.ID, &q.Title, &q.Description, &q.Category)
	if err == sql.ErrNoRows {
		return nil, nil
	} else if err != nil {
		return nil, err
	}

	rows, err := r.db.Query(dbx.Rebind(r.db, "SELECT id, type, difficulty, text FROM questions WHERE quiz_id = ?"), id)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	for rows.Next() {
		var quest quizdomain.Question
		var difficulty sql.NullInt64
		if err := rows.Scan(&quest.ID, &quest.Type, &difficulty, &quest.Text); err != nil {
			return nil, err
		}
		if difficulty.Valid {
			quest.Difficulty = int(difficulty.Int64)
		}
		q.Questions = append(q.Questions, quest)
	}

	return &q, nil
}

func (r *QuizRepository) GetQuestion(quizID, questionID string) (*quizdomain.Question, error) {
	var quest quizdomain.Question
	var optionsJSON string
	var correctText sql.NullString
	var multiJSON sql.NullString
	var imageURL sql.NullString
	var explanation sql.NullString
	var difficulty sql.NullInt64

	row := r.db.QueryRow(dbx.Rebind(r.db, `
		SELECT id, type, text, options, correct_answer_index, correct_text, correct_multi, image_url, explanation, difficulty
		FROM questions
		WHERE quiz_id = ? AND id = ?`), quizID, questionID)

	err := row.Scan(&quest.ID, &quest.Type, &quest.Text, &optionsJSON, &quest.CorrectAnswerIndex, &correctText, &multiJSON, &imageURL, &explanation, &difficulty)
	if err == sql.ErrNoRows {
		return nil, nil
	} else if err != nil {
		return nil, err
	}

	_ = json.Unmarshal([]byte(optionsJSON), &quest.Options)
	quest.CorrectText = correctText.String
	quest.ImageURL = imageURL.String
	quest.Explanation = explanation.String
	if difficulty.Valid {
		quest.Difficulty = int(difficulty.Int64)
	}
	if multiJSON.Valid {
		_ = json.Unmarshal([]byte(multiJSON.String), &quest.CorrectMulti)
	}

	return &quest, nil
}

func (r *QuizRepository) Create(q *quizdomain.Quiz) error {
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

	if _, err := tx.Exec(dbx.Rebind(r.db, "INSERT INTO quizzes (id, title, description, category) VALUES (?, ?, ?, ?)"), q.ID, q.Title, q.Description, q.Category); err != nil {
		_ = tx.Rollback()
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
		if _, err := tx.Exec(dbx.Rebind(r.db, "INSERT INTO questions (id, quiz_id, type, text, options, correct_answer_index, correct_text, correct_multi, image_url, explanation, difficulty) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"),
			quest.ID, q.ID, quest.Type, quest.Text, string(optionsJSON), quest.CorrectAnswerIndex, quest.CorrectText, string(multiJSON), quest.ImageURL, quest.Explanation, quest.Difficulty); err != nil {
			_ = tx.Rollback()
			return err
		}
	}

	return tx.Commit()
}

func (r *QuizRepository) Update(q *quizdomain.Quiz) error {
	tx, err := r.db.Begin()
	if err != nil {
		return err
	}

	if q.Category == "" {
		q.Category = "Разное"
	}

	if _, err := tx.Exec(dbx.Rebind(r.db, "UPDATE quizzes SET title = ?, description = ?, category = ? WHERE id = ?"), q.Title, q.Description, q.Category, q.ID); err != nil {
		_ = tx.Rollback()
		return err
	}

	if _, err := tx.Exec(dbx.Rebind(r.db, "DELETE FROM questions WHERE quiz_id = ?"), q.ID); err != nil {
		_ = tx.Rollback()
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
		if _, err := tx.Exec(dbx.Rebind(r.db, "INSERT INTO questions (id, quiz_id, type, text, options, correct_answer_index, correct_text, correct_multi, image_url, explanation, difficulty) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)"),
			quest.ID, q.ID, quest.Type, quest.Text, string(optionsJSON), quest.CorrectAnswerIndex, quest.CorrectText, string(multiJSON), quest.ImageURL, quest.Explanation, quest.Difficulty); err != nil {
			_ = tx.Rollback()
			return err
		}
	}

	return tx.Commit()
}

func (r *QuizRepository) Delete(id string) error {
	_, err := r.db.Exec(dbx.Rebind(r.db, "DELETE FROM quizzes WHERE id = ?"), id)
	return err
}

func (r *QuizRepository) SaveReport(report *quizdomain.QuizReport) error {
	if report.CreatedAt.IsZero() {
		report.CreatedAt = time.Now().UTC()
	}
	if report.ID == "" {
		report.ID = uuid.New().String()
	}

	_, err := r.db.Exec(
		dbx.Rebind(r.db, "INSERT INTO reports (id, quiz_id, question_id, message, question_text, created_at) VALUES (?, ?, ?, ?, ?, ?)"),
		report.ID,
		report.QuizID,
		report.QuestionID,
		report.Message,
		report.QuestionText,
		report.CreatedAt,
	)
	return err
}
