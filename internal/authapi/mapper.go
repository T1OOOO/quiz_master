package authapi

import (
	authdomain "quiz_master/internal/auth/domain"
	authdto "quiz_master/internal/authapi/dto"
)

func toDTOQuota(q *authdomain.UserQuota) *authdto.UserQuota {
	if q == nil {
		return nil
	}
	return &authdto.UserQuota{
		QuizzesCompleted:  q.QuizzesCompleted,
		QuestionsAnswered: q.QuestionsAnswered,
		QuizzesLimit:      q.QuizzesLimit,
		QuestionsLimit:    q.QuestionsLimit,
		AttemptsLimit:     q.AttemptsLimit,
		AttemptsUsed:      q.AttemptsUsed,
	}
}

func toDTOLeaderboard(entries []map[string]interface{}) []authdto.LeaderboardEntry {
	out := make([]authdto.LeaderboardEntry, 0, len(entries))
	for _, entry := range entries {
		out = append(out, authdto.LeaderboardEntry{
			Username:  getString(entry["username"]),
			Score:     getInt(entry["score"]),
			Total:     getInt(entry["total"]),
			QuizTitle: getString(entry["quiz_title"]),
		})
	}
	return out
}

func getString(v interface{}) string {
	if s, ok := v.(string); ok {
		return s
	}
	return ""
}

func getInt(v interface{}) int {
	switch val := v.(type) {
	case int:
		return val
	case int64:
		return int(val)
	case float64:
		return int(val)
	default:
		return 0
	}
}
