package service

import (
	"fmt"
	"io/fs"
	"log/slog"
	"os"
	"path/filepath"
	"quiz_master/internal/models"
	"quiz_master/internal/store"

	"gopkg.in/yaml.v3"
)

type QuizService struct {
	repo *store.QuizStore
}

func NewQuizService(repo *store.QuizStore) *QuizService {
	return &QuizService{repo: repo}
}

func (s *QuizService) ListQuizzes() ([]models.Quiz, error) {
	return s.repo.List()
}

func (s *QuizService) GetQuiz(id string) (*models.Quiz, error) {
	return s.repo.Get(id)
}

func (s *QuizService) CreateQuiz(q *models.Quiz) error {
	return s.repo.Create(q)
}

func (s *QuizService) UpdateQuiz(q *models.Quiz) error {
	return s.repo.Update(q)
}

func (s *QuizService) DeleteQuiz(id string) error {
	return s.repo.Delete(id)
}

func (s *QuizService) CheckAnswer(quizID, questionID string, answer interface{}) (*models.AnswerResult, error) {
	q, err := s.repo.Get(quizID)
	if err != nil {
		return nil, err
	}
	if q == nil {
		return nil, fmt.Errorf("quiz not found: %s", quizID)
	}

	var question *models.Question
	for _, quest := range q.Questions {
		if quest.ID == questionID {
			question = &quest
			break
		}
	}

	if question == nil {
		return nil, fmt.Errorf("question not found: %s in quiz %s", questionID, quizID)
	}

	correct := false
	var correctAnswer interface{}

	var correctTextStr string
	switch question.Type {
	case "choice":
		// Handle both int and float64 (JSON numbers can be either)
		var ansIdx int
		switch v := answer.(type) {
		case int:
			ansIdx = v
		case float64:
			ansIdx = int(v)
		case int64:
			ansIdx = int(v)
		default:
			// Try to convert
			if f, ok := answer.(float64); ok {
				ansIdx = int(f)
			}
		}
		correct = ansIdx == question.CorrectAnswerIndex
		correctAnswer = question.CorrectAnswerIndex
		if question.CorrectAnswerIndex >= 0 && question.CorrectAnswerIndex < len(question.Options) {
			correctTextStr = question.Options[question.CorrectAnswerIndex]
		}
	case "text":
		ansText, ok := answer.(string)
		if ok {
			correct = ansText == question.CorrectText
		}
		correctAnswer = question.CorrectText
		correctTextStr = question.CorrectText
	case "multi":
		ansMulti, ok := answer.([]interface{})
		if ok {
			correct = true
			if len(ansMulti) != len(question.CorrectMulti) {
				correct = false
			} else {
				for _, v := range ansMulti {
					val := int(v.(float64))
					found := false
					for _, c := range question.CorrectMulti {
						if c == val {
							found = true
							break
						}
					}
					if !found {
						correct = false
						break
					}
				}
			}
		}
		correctAnswer = question.CorrectMulti
		// Just a placeholder for multi for now
		correctTextStr = "Multiple correct options"
	}

	return &models.AnswerResult{
		Correct:       correct,
		CorrectAnswer: correctAnswer,
		CorrectText:   correctTextStr,
		Explanation:   question.Explanation,
	}, nil
}

func (s *QuizService) SyncFromFiles(dir string) error {
	slog.Info("Syncing quizzes from directory", "dir", dir)

	processedIDs := make(map[string]bool)

	err := filepath.WalkDir(dir, func(path string, d fs.DirEntry, err error) error {
		if err != nil {
			return err
		}
		if d.IsDir() {
			return nil
		}

		ext := filepath.Ext(path)
		if ext == ".yaml" || ext == ".yml" {
			data, err := os.ReadFile(path)
			if err != nil {
				slog.Error("failed to read quiz file", "path", path, "error", err)
				return nil
			}

			var q models.Quiz
			if err := yaml.Unmarshal(data, &q); err != nil {
				slog.Error("failed to unmarshal quiz", "path", path, "error", err)
				return nil
			}

			// Infer category from path (relative to quizzes dir) if not already set
			if q.Category == "" {
				rel, err := filepath.Rel(dir, path)
				if err == nil {
					parent := filepath.Dir(rel)
					if parent != "." {
						q.Category = parent
					}
				}
			}

			if q.Category == "" {
				q.Category = "Разное"
			}

			// Simple check: if quiz already exists, don't re-create
			existing, err := s.repo.Get(q.ID)
			if err != nil {
				slog.Error("failed to check existence", "id", q.ID, "error", err)
				return nil
			}

			if existing == nil {
				if err := s.repo.Create(&q); err != nil {
					slog.Error("failed to create quiz from file", "id", q.ID, "error", err)
				} else {
					slog.Info("imported quiz from file", "id", q.ID, "title", q.Title, "category", q.Category)
				}
			} else {
				// Always update to ensure questions are synced
				if err := s.repo.Update(&q); err != nil {
					slog.Error("failed to update quiz from file", "id", q.ID, "error", err)
				} else {
					slog.Info("updated quiz from file", "id", q.ID, "title", q.Title, "category", q.Category)
				}
			}
			processedIDs[q.ID] = true
		}
		return nil
	})

	if err != nil {
		return err
	}

	// Purge quizzes that are in DB but no longer in files
	allQuizzes, err := s.repo.List()
	if err != nil {
		slog.Error("failed to list quizzes for cleanup", "error", err)
	} else {
		for _, q := range allQuizzes {
			if !processedIDs[q.ID] {
				slog.Info("purging stale quiz from database", "id", q.ID, "title", q.Title)
				if err := s.repo.Delete(q.ID); err != nil {
					slog.Error("failed to delete stale quiz", "id", q.ID, "error", err)
				}
			}
		}
	}

	return nil
}

func min(a, b int) int {
	if a < b {
		return a
	}
	return b
}
