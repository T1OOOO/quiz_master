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

// Explicit legacy quiz identities; do not derive identity from a file location.
// v1's ASCII folding loses the Cyrillic topic and collapses these eight packs.
var legacyQuizIDs = map[string]string{
	"gastronomy_сыры_и_молочные_продукты": "gastronomy-cheeses-and-dairy",
	"gastronomy_техника_приготовления":    "gastronomy-cooking-techniques",
	"gastronomy_напитки_и_алкоголь":       "gastronomy-drinks-and-alcohol",
	"gastronomy_фрукты_и_овощи":           "gastronomy-fruits-and-vegetables",
	"gastronomy_мясо_и_рыба":              "gastronomy-meat-and-fish",
	"gastronomy_специи_и_ингредиенты":     "gastronomy-spices-and-ingredients",
	"gastronomy_сладости_и_десерты":       "gastronomy-sweets-and-desserts",
	"gastronomy_традиции_и_этикет":        "gastronomy-traditions-and-etiquette",
}

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
	return ImportWithTaxonomy(path, nil)
}

// ImportWithTaxonomy is the strict path for newly annotated raw sources. The
// compatibility Import entrypoint remains usable for legacy sources that have
// no taxonomy reference or annotations.
func ImportWithTaxonomy(path string, taxonomy *Taxonomy) (Draft, Manifest, error) {
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
	if e = allowed(obj, "id title description category taxonomy_ref questions", path); e != nil {
		return Draft{}, Manifest{}, e
	}
	for _, key := range []string{"id", "title", "description", "category"} {
		if _, ok := nonblank(obj[key]); !ok {
			return fail("required", path+"#/"+key)
		}
	}
	sourceID := obj["id"].(string)
	quizID := stableID(sourceID)
	mappingVersion := "legacy-choice/v1"
	if mapped, ok := legacyQuizIDs[sourceID]; ok {
		quizID, mappingVersion = mapped, "legacy-choice/v2"
	}
	if !idPattern.MatchString(quizID) {
		return fail("invalid_id", path+"#/id")
	}
	questions, ok := obj["questions"].([]any)
	if !ok || len(questions) == 0 {
		return fail("required", path+"#/questions")
	}
	sourcePath := filepath.ToSlash(filepath.Clean(path))
	d := Draft{Contract: "quiz-contract/v1", State: "draft", QuizID: quizID, Locale: "ru", Revision: Revision{Number: 1}}
	if raw, exists := obj["taxonomy_ref"]; exists {
		ref, ok := rawTaxonomyRef(raw)
		if !ok {
			return fail("taxonomy_reference", path+"#/taxonomy_ref")
		}
		d.TaxonomyRef = ref
	}
	m := Manifest{MappingVersion: mappingVersion, SourcePath: sourcePath, SourceSHA256: hashBytes(canonicalSource), SourceQuizID: sourceID, CanonicalQuizID: quizID, Category: obj["category"].(string), Title: obj["title"].(string), Description: obj["description"].(string)}
	seen := map[string]string{}
	for pos, value := range questions {
		where := fmt.Sprintf("%s#/questions/%d", path, pos)
		q, ok := value.(map[string]any)
		if !ok {
			return fail("invalid_json", where)
		}
		if e = allowed(q, "id type difficulty editorial_tag_ids context_tag_ids text options correct_answer correct_multi explanation media", where); e != nil {
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
		var difficultyLevel *int
		if q["difficulty"] != nil {
			n, ok := integer(q["difficulty"])
			if !ok || n < 1 || n > 10 {
				return fail("difficulty", where)
			}
			difficulty = difficultyBand(n)
			difficultyLevel = &n
		}
		editorialRaw, editorialPresent := q["editorial_tag_ids"]
		if editorialPresent && editorialRaw == nil {
			return fail("tag_ids", where)
		}
		editorialTagIDs, err := rawTagIDs(editorialRaw)
		if err != nil {
			return fail("tag_ids", where)
		}
		contextRaw, contextPresent := q["context_tag_ids"]
		if contextPresent && contextRaw == nil {
			return fail("tag_ids", where)
		}
		contextTagIDs, err := rawTagIDs(contextRaw)
		if err != nil {
			return fail("tag_ids", where)
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
		question := Question{QuestionID: qid, Revision: Revision{Number: 1}, Stem: stem, Options: options, Difficulty: difficulty, DifficultyLevel: difficultyLevel, EditorialTagIDs: editorialTagIDs, ContextTagIDs: contextTagIDs, Source: map[string]string{"uri": sourcePath}, AnswerKind: "single_choice", Grading: Grading{CorrectOptionID: options[answer].OptionID}}
		if raw, exists := q["media"]; exists {
			entries, ok := raw.([]any)
			if !ok {
				return fail("media", where+"/media")
			}
			media := make([]Media, len(entries))
			for i, entry := range entries {
				item, ok := entry.(map[string]any)
				if !ok {
					return fail("media", where+"/media")
				}
				if e = allowed(item, "uri kind alt", where+"/media"); e != nil {
					return Draft{}, Manifest{}, e
				}
				if _, ok := nonblank(item["uri"]); !ok {
					return fail("media", where+"/media")
				}
				media[i] = Media{}
				for key, value := range item {
					text, ok := value.(string)
					if !ok {
						return fail("media", where+"/media")
					}
					media[i][key] = text
				}
			}
			question.Media = &media
		}
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
	if hasAnnotations(d) {
		if e = validateTaxonomyLinks(d, taxonomy); e != nil {
			return Draft{}, Manifest{}, e
		}
	}
	return d, m, nil
}

func rawTaxonomyRef(v any) (*TaxonomyRef, bool) {
	m, ok := v.(map[string]any)
	if !ok || len(m) != 2 {
		return nil, false
	}
	id, idOK := nonblank(m["taxonomy_id"])
	hash, hashOK := nonblank(m["taxonomy_sha256"])
	if !idOK || !hashOK || !taxonomySHA256Pattern.MatchString(hash) {
		return nil, false
	}
	return &TaxonomyRef{TaxonomyID: id, TaxonomySHA256: hash}, true
}
func rawTagIDs(v any) ([]string, error) {
	if v == nil {
		return nil, nil
	}
	values, ok := v.([]any)
	if !ok {
		return nil, &Error{"tag_ids", ""}
	}
	ids := make([]string, len(values))
	for i, value := range values {
		id, ok := nonblank(value)
		if !ok {
			return nil, &Error{"tag_ids", ""}
		}
		ids[i] = id
	}
	if err := validateTagIDs(ids, ""); err != nil {
		return nil, err
	}
	return ids, nil
}
