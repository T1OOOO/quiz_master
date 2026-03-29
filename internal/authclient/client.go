package authclient

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	authdomain "quiz_master/internal/auth/domain"
	authdto "quiz_master/internal/authapi/dto"
	"quiz_master/internal/observability"
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

func (c *Client) Register(req *authdomain.AuthRequest) (*authdomain.AuthResponse, error) {
	var out authdomain.AuthResponse
	if err := c.doJSONRequest(http.MethodPost, "/api/register", req, &out, false); err != nil {
		return nil, err
	}
	return &out, nil
}

func (c *Client) Login(req *authdomain.AuthRequest) (*authdomain.AuthResponse, error) {
	var out authdomain.AuthResponse
	if err := c.doJSONRequest(http.MethodPost, "/api/login", req, &out, false); err != nil {
		return nil, err
	}
	return &out, nil
}

func (c *Client) GuestLogin(username string) (*authdomain.AuthResponse, error) {
	var out authdomain.AuthResponse
	if err := c.doJSONRequest(http.MethodPost, "/api/guest", map[string]string{"username": username}, &out, false); err != nil {
		return nil, err
	}
	return &out, nil
}

func (c *Client) Refresh(refreshToken string) (*authdomain.AuthResponse, error) {
	var out authdomain.AuthResponse
	if err := c.doJSONRequest(http.MethodPost, "/api/refresh", map[string]string{"refresh_token": refreshToken}, &out, false); err != nil {
		return nil, err
	}
	return &out, nil
}

func (c *Client) SubmitResult(userID, quizID string, score, totalQuestions int) error {
	return c.doJSONRequest(http.MethodPost, "/internal/auth/results", authdto.SubmitResultRequest{
		UserID:         userID,
		QuizID:         quizID,
		Score:          score,
		TotalQuestions: totalQuestions,
	}, nil, true)
}

func (c *Client) GetLeaderboard(limit int) ([]authdto.LeaderboardEntry, error) {
	path := "/internal/auth/leaderboard"
	if limit > 0 {
		path += "?limit=" + url.QueryEscape(fmt.Sprintf("%d", limit))
	}
	var out []authdto.LeaderboardEntry
	if err := c.doJSONRequest(http.MethodGet, path, nil, &out, true); err != nil {
		return nil, err
	}
	return out, nil
}

func (c *Client) GetUserQuota(userID string) (*authdomain.UserQuota, error) {
	var payload authdto.UserQuota
	err := c.doJSONRequest(http.MethodGet, "/internal/auth/quota/"+url.PathEscape(userID), nil, &payload, true)
	if err == errNotFound {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &authdomain.UserQuota{
		QuizzesCompleted:  payload.QuizzesCompleted,
		QuestionsAnswered: payload.QuestionsAnswered,
		QuizzesLimit:      payload.QuizzesLimit,
		QuestionsLimit:    payload.QuestionsLimit,
		AttemptsLimit:     payload.AttemptsLimit,
		AttemptsUsed:      payload.AttemptsUsed,
	}, nil
}

var errNotFound = fmt.Errorf("auth resource not found")

func (c *Client) doJSON(method, path string, body any, out any) error {
	return c.doJSONRequest(method, path, body, out, true)
}

func (c *Client) doJSONRequest(method, path string, body any, out any, withToken bool) error {
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
	if withToken && c.token != "" {
		req.Header.Set("X-Internal-Token", c.token)
	}

	start := time.Now()
	resp, err := c.http.Do(req)
	statusCode := 0
	if resp != nil {
		statusCode = resp.StatusCode
	}
	observability.RecordUpstreamRequest(c.service, "auth", method, path, statusCode, time.Since(start), err)
	if err != nil {
		return err
	}
	defer resp.Body.Close()

	if resp.StatusCode == http.StatusNotFound {
		return errNotFound
	}
	if resp.StatusCode >= 300 {
		data, _ := io.ReadAll(io.LimitReader(resp.Body, 4096))
		return fmt.Errorf("auth request failed: %s: %s", resp.Status, strings.TrimSpace(string(data)))
	}
	if out == nil {
		return nil
	}
	return json.NewDecoder(resp.Body).Decode(out)
}
