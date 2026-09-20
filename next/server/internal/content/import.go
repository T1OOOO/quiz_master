package content

import (
	"encoding/json"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"sort"
	"strings"
)

var idInvalid = regexp.MustCompile(`[^a-z0-9-]+`)
var idPattern = regexp.MustCompile(`^[a-z][a-z0-9-]{2,63}$`)

// Preserve legal legacy ASCII IDs; fold case, replace separator runs, prefix short
// or digit-leading IDs. Never truncate: long/unrepresentable IDs fail closed.
func stableID(s string) string {
	s = strings.Trim(idInvalid.ReplaceAllString(strings.ToLower(s), "-"), "-")
	if s != "" && (len(s) < 3 || s[0] < 'a' || s[0] > 'z') {
		s = "id-" + s
	}
	return s
}
func allowed(m map[string]any, keys, path string) error {
	set := map[string]bool{}
	for _, k := range strings.Fields(keys) {
		set[k] = true
	}
	for k := range m {
		if !set[k] {
			return &Error{"unknown_field", path}
		}
	}
	return nil
}
func nonblank(v any) (string, bool) { s, ok := v.(string); return s, ok && strings.TrimSpace(s) != "" }
func integer(v any) (int, bool) {
	n, ok := v.(json.Number)
	if !ok {
		return 0, false
	}
	i, e := n.Int64()
	if e != nil || int64(int(i)) != i {
		return 0, false
	}
	return int(i), true
}

func Import(path string) (Draft, Manifest, error) {
	b, e := os.ReadFile(path)
	if e != nil {
		return Draft{}, Manifest{}, &Error{"read", path}
	}
	fail := func(code, where string) (Draft, Manifest, error) { return Draft{}, Manifest{}, &Error{code, where} }
	v, e := decodeJSON(b, path)
	if e != nil {
		return Draft{}, Manifest{}, e
	}
	obj, ok := v.(map[string]any)
	if !ok {
		return fail("invalid_json", path)
	}
	canonicalSource, e := canonicalSourceBytes(b)
	if e != nil {
		return fail("invalid_json", path)
	}
	if e = allowed(obj, "id title description category questions", path); e != nil {
		return Draft{}, Manifest{}, e
	}
	for _, key := range []string{"id", "title", "description", "category"} {
		if _, ok := nonblank(obj[key]); !ok {
			return fail("required", path+"#/"+key)
		}
	}
	sourceID := obj["id"].(string)
	quizID := stableID(sourceID)
	if !idPattern.MatchString(quizID) {
		return fail("invalid_id", path+"#/id")
	}
	questions, ok := obj["questions"].([]any)
	if !ok || len(questions) == 0 {
		return fail("required", path+"#/questions")
	}
	sourcePath := filepath.ToSlash(filepath.Clean(path))
	d := Draft{Contract: "quiz-contract/v1", State: "draft", QuizID: quizID, Locale: "ru", Revision: Revision{Number: 1}}
	m := Manifest{MappingVersion: "legacy-choice/v1", SourcePath: sourcePath, SourceSHA256: hashBytes(canonicalSource), SourceQuizID: sourceID, CanonicalQuizID: quizID, Category: obj["category"].(string), Title: obj["title"].(string), Description: obj["description"].(string)}
	seen := map[string]string{}
	for pos, value := range questions {
		where := fmt.Sprintf("%s#/questions/%d", path, pos)
		q, ok := value.(map[string]any)
		if !ok {
			return fail("invalid_json", where)
		}
		if e = allowed(q, "id type difficulty text options correct_answer correct_multi explanation", where); e != nil {
			return Draft{}, Manifest{}, e
		}
		qSource, ok := nonblank(q["id"])
		if !ok {
			return fail("required", where+"/id")
		}
		qid := stableID(qSource)
		if !idPattern.MatchString(qid) {
			return fail("invalid_id", where+"/id")
		}
		where += " (" + qid + ")"
		if previous, found := seen[qid]; found {
			if previous == qSource {
				return fail("duplicate_id", where)
			}
			return fail("id_collision", where)
		}
		seen[qid] = qSource
		if q["type"] != "choice" {
			return fail("type", where)
		}
		stem, ok := nonblank(q["text"])
		if !ok {
			return fail("required", where+"/text")
		}
		rawOptions, ok := q["options"].([]any)
		if !ok || len(rawOptions) < 4 || len(rawOptions) > 6 {
			return fail("option_count", where)
		}
		answer, ok := integer(q["correct_answer"])
		if !ok || answer < 0 || answer >= len(rawOptions) {
			return fail("answer_index", where)
		}
		difficulty := "unknown"
		if q["difficulty"] != nil {
			n, ok := integer(q["difficulty"])
			if !ok || n < 1 || n > 10 {
				return fail("difficulty", where)
			}
			switch {
			case n <= 3:
				difficulty = "easy"
			case n <= 7:
				difficulty = "medium"
			default:
				difficulty = "hard"
			}
		}
		options := make([]Option, len(rawOptions))
		mapping := QuestionMap{SourceID: qSource, CanonicalID: qid, Options: make([]OptionMap, len(rawOptions))}
		if v, exists := q["explanation"]; exists {
			s, ok := nonblank(v)
			if !ok {
				return fail("required", where+"/explanation")
			}
			mapping.Explanation = s
		}
		for i, v := range rawOptions {
			text, ok := nonblank(v)
			if !ok {
				return fail("option_blank", where)
			}
			oid := fmt.Sprintf("%s-opt-%d", qid, i+1)
			if !idPattern.MatchString(oid) {
				oid = fmt.Sprintf("opt-%d", i+1)
			}
			options[i] = Option{OptionID: oid, Text: text}
			mapping.Options[i] = OptionMap{SourceIndex: i, CanonicalID: oid}
		}
		question := Question{QuestionID: qid, Revision: Revision{Number: 1}, Stem: stem, Options: options, Difficulty: difficulty, Source: map[string]string{"uri": sourcePath}, AnswerKind: "single_choice", Grading: Grading{CorrectOptionID: options[answer].OptionID}}
		if q["correct_multi"] != nil {
			indexes, ok := q["correct_multi"].([]any)
			if !ok || len(indexes) == 1 {
				return fail("multi_index", where)
			}
			if len(indexes) > 0 {
				set := map[int]bool{}
				ints := []int{}
				for _, v := range indexes {
					i, ok := integer(v)
					if !ok || i < 0 || i >= len(options) || set[i] {
						return fail("multi_index", where)
					}
					set[i] = true
					ints = append(ints, i)
				}
				if !set[answer] {
					return fail("multi_conflict", where)
				}
				sort.Ints(ints)
				ids := make([]string, len(ints))
				for i, index := range ints {
					ids[i] = options[index].OptionID
				}
				question.AnswerKind = "multiple_choice"
				question.Grading = Grading{CorrectOptionIDs: ids}
			}
		}
		d.Questions = append(d.Questions, question)
		m.Questions = append(m.Questions, mapping)
	}
	Rehash(&d)
	return d, m, nil
}
