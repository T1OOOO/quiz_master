package token

import (
	"errors"
	"time"

	authdomain "quiz_master/internal/auth/domain"

	"github.com/golang-jwt/jwt/v5"
)

var DefaultSecretKey = []byte("your-secret-key-change-this-in-prod")

type Manager struct {
	secretKey []byte
	ttl       time.Duration
}

func NewManager(secret string, ttl time.Duration) *Manager {
	key := []byte(secret)
	if len(key) == 0 {
		key = DefaultSecretKey
	}
	if ttl <= 0 {
		ttl = 24 * time.Hour
	}
	return &Manager{secretKey: key, ttl: ttl}
}

func NewLegacyManager() *Manager {
	return &Manager{secretKey: DefaultSecretKey, ttl: 24 * time.Hour}
}

func (m *Manager) SecretKey() []byte {
	return m.secretKey
}

func (m *Manager) Generate(claims authdomain.Claims) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id":  claims.UserID,
		"username": claims.Username,
		"role":     claims.Role,
		"exp":      time.Now().Add(m.ttl).Unix(),
	})

	return token.SignedString(m.secretKey)
}

func (m *Manager) Parse(tokenString string) (*jwt.Token, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, errors.New("unexpected signing method")
		}
		return m.secretKey, nil
	})
	if err != nil {
		return nil, err
	}
	if !token.Valid {
		return nil, errors.New("invalid token")
	}
	return token, nil
}
