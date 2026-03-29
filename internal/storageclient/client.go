package storageclient

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"quiz_master/internal/observability"
	quizdomain "quiz_master/internal/quiz/domain"
	storagedto "quiz_master/internal/storageapi/dto"
	"quiz_master/internal/tracing"
)

type Client struct {
	baseURL string
	service string
	token   string
	http    *http.Client
}

func New(baseURL, token string) *Client {
	return NewForService("server", baseURL, token)
}

func NewForService(serviceName, baseURL, token string) *Client {
	return &Client{
		baseURL: strings.TrimRight(baseURL, "/"),
		service: serviceName,
		token:   token,
		http: &http.Client{
			Timeout:   30 * time.Second,
			Transport: tracing.NewTransport(http.DefaultTransport),
		},
	}
}

func (c *Client) List() ([]quizdomain.Quiz, error) {
	var payload []storagedto.Quiz
	err := c.doJSON(http.MethodGet, "/internal/storage/quizzes", nil, &payload)
	if err != nil {
		return nil, err
	}
	out := make([]quizdomain.Quiz, len(payload))
	for i := range payload {
		domainQuiz := toDomainQuiz(&payload[i])
		if domainQuiz != nil {
			out[i] = *domainQuiz
		}
	}
	return out, nil
}

func (c *Client) Get(id string) (*quizdomain.Quiz, error) {
	var payload storagedto.Quiz
	err := c.doJSON(http.MethodGet, "/internal/storage/quizzes/"+url.PathEscape(id), nil, &payload)
	if err == errNotFound {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return toDomainQuiz(&payload), nil
}

func (c *Client) GetSummary(id string) (*quizdomain.Quiz, error) {
	var payload storagedto.Quiz
	err := c.doJSON(http.MethodGet, "/internal/storage/quizzes/"+url.PathEscape(id)+"/summary", nil, &payload)
	if err == errNotFound {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return toDomainQuiz(&payload), nil
}

func (c *Client) GetQuestion(quizID, questionID string) (*quizdomain.Question, error) {
	var payload storagedto.Question
	path := "/internal/storage/quizzes/" + url.PathEscape(quizID) + "/questions/" + url.PathEscape(questionID)
	err := c.doJSON(http.MethodGet, path, nil, &payload)
	if err == errNotFound {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	out := toDomainQuestion(payload)
	return &out, nil
}

func (c *Client) Create(q *quizdomain.Quiz) error {
	return c.doJSON(http.MethodPost, "/internal/storage/quizzes", toDTOQuiz(q), nil)
}

func (c *Client) Update(q *quizdomain.Quiz) error {
	return c.doJSON(http.MethodPut, "/internal/storage/quizzes/"+url.PathEscape(q.ID), toDTOQuiz(q), nil)
}

func (c *Client) Delete(id string) error {
	return c.doJSON(http.MethodDelete, "/internal/storage/quizzes/"+url.PathEscape(id), nil, nil)
}

func (c *Client) SaveReport(report *quizdomain.QuizReport) error {
	return c.doJSON(http.MethodPost, "/internal/storage/reports", storagedto.ReportRequest{
		QuizID:       report.QuizID,
		QuestionID:   report.QuestionID,
		Message:      report.Message,
		QuestionText: report.QuestionText,
	}, nil)
}

func (c *Client) GetQuizTitle(id string) (string, error) {
	q, err := c.GetSummary(id)
	if err != nil {
		return "", err
	}
	if q == nil {
		return "", nil
	}
	return q.Title, nil
}

var errNotFound = fmt.Errorf("storage resource not found")

func (c *Client) doJSON(method, path string, body any, out any) error {
	var payload io.Reader
	if body != nil {
		data, err := json.Marshal(body)
		if err != nil {
			return err
		}
		payload = bytes.NewReader(data)
	}

	req, err := http.NewRequest(method, c.baseURL+path, payload)
	if err != nil {
		return err
	}
	req.Header.Set("Accept", "application/json")
	if body != nil {
		req.Header.Set("Content-Type", "application/json")
	}
	if c.token != "" {
		req.Header.Set("X-Internal-Token", c.token)
	}

	start := time.Now()
	resp, err := c.http.Do(req)
	statusCode := 0
	if resp != nil {
		statusCode = resp.StatusCode
	}
	observability.RecordUpstreamRequest(c.service, "storage", method, path, statusCode, time.Since(start), err)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return errNotFound
	}
	if resp.StatusCode >= 300 {
		data, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
		return fmt.Errorf("storage request failed: %s: %s", resp.Status, strings.TrimSpace(string(data)))
	}

	if out == nil {
		return nil
	}
	return json.NewDecoder(resp.Body).Decode(out)
}
