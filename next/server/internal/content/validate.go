package content

import (
	"encoding/json"
	"os"
	"path/filepath"
	"sort"
	"strings"
	"time"

	"github.com/santhosh-tekuri/jsonschema/v6"
)

// ValidateSchema uses a maintained Draft 2020-12 implementation. All resources
// come from the supplied local file; remote resolution is disabled.
func ValidateSchema(data []byte, schemaPath, path string) error {
	value, e := decodeJSON(data, path)
	if e != nil {
		return e
	}
	raw, e := os.ReadFile(schemaPath)
	if e != nil {
		return &Error{"schema_load", schemaPath}
	}
	doc, e := decodeJSON(raw, schemaPath)
	if e != nil {
		return &Error{"schema_load", schemaPath}
	}
	c := jsonschema.NewCompiler()
	c.DefaultDraft(jsonschema.Draft2020)
	c.AssertFormat()
	c.UseLoader(nil)
	const uri = "https://quizctl.invalid/local-schema"
	if e = c.AddResource(uri, doc); e != nil {
		return &Error{"schema_load", schemaPath}
	}
	schema, e := c.Compile(uri)
	if e != nil {
		return &Error{"schema_load", schemaPath}
	}
	if e = schema.Validate(value); e != nil {
		// Only JSON pointer locations are exposed; validator messages can contain
		// grading values. Sort leaf pointers for deterministic multi-error output.
		locations := []string{}
		var visit func(*jsonschema.ValidationError)
		visit = func(v *jsonschema.ValidationError) {
			if len(v.Causes) == 0 {
				parts := append([]string(nil), v.InstanceLocation...)
				for i, p := range parts {
					parts[i] = strings.ReplaceAll(strings.ReplaceAll(p, "~", "~0"), "/", "~1")
				}
				locations = append(locations, "/"+strings.Join(parts, "/"))
			}
			for _, cause := range v.Causes {
				visit(cause)
			}
		}
		if validation, ok := e.(*jsonschema.ValidationError); ok {
			visit(validation)
		}
		sort.Strings(locations)
		if len(locations) > 0 {
			path += "#" + locations[0]
		}
		return &Error{"schema_invalid", path}
	}
	return nil
}
func ValidateDraft(d Draft, schemaPath string) error {
	data, e := json.Marshal(d)
	if e != nil {
		return &Error{"encode", d.QuizID}
	}
	if e = ValidateSchema(data, schemaPath, d.QuizID); e != nil {
		return e
	}
	return validateDraftLinks(d)
}
func validateDraftLinks(d Draft) error {
	if strings.TrimSpace(d.Locale) == "" {
		return &Error{"required", d.QuizID + "/locale"}
	}
	seen := map[string]bool{}
	// Validate relationships before hashes, so malformed keys get actionable codes.
	for _, q := range d.Questions {
		where := d.QuizID + "/" + q.QuestionID
		if seen[q.QuestionID] {
			return &Error{"duplicate_id", where}
		}
		seen[q.QuestionID] = true
		if strings.TrimSpace(q.Stem) == "" || strings.TrimSpace(q.Source["uri"]) == "" {
			return &Error{"required", where}
		}
		options := map[string]bool{}
		for _, o := range q.Options {
			if options[o.OptionID] {
				return &Error{"duplicate_id", where + "/" + o.OptionID}
			}
			options[o.OptionID] = true
			if strings.TrimSpace(o.Text) == "" {
				return &Error{"required", where + "/" + o.OptionID}
			}
			if o.Media != nil && strings.TrimSpace(o.Media["uri"]) == "" {
				return &Error{"required", where + "/media"}
			}
		}
		if q.Media != nil {
			for _, m := range *q.Media {
				if strings.TrimSpace(m["uri"]) == "" {
					return &Error{"required", where + "/media"}
				}
			}
		}
		g := q.Grading
		switch q.AnswerKind {
		case "single_choice":
			if g.CorrectOptionID == "" || len(g.CorrectOptionIDs) != 0 || len(g.AcceptedVariants) != 0 {
				return &Error{"grading_kind", where}
			}
			if !options[g.CorrectOptionID] {
				return &Error{"grading_reference", where}
			}
		case "multiple_choice":
			if len(g.CorrectOptionIDs) == 0 || g.CorrectOptionID != "" || len(g.AcceptedVariants) != 0 {
				return &Error{"grading_kind", where}
			}
			keys := map[string]bool{}
			for _, id := range g.CorrectOptionIDs {
				if keys[id] || !options[id] {
					return &Error{"grading_reference", where}
				}
				keys[id] = true
			}
		case "normalized_text":
			if len(g.AcceptedVariants) == 0 || g.CorrectOptionID != "" || len(g.CorrectOptionIDs) != 0 {
				return &Error{"grading_kind", where}
			}
			keys := map[string]bool{}
			for _, v := range g.AcceptedVariants {
				s := NormalizeText(v)
				if s == "" || keys[s] {
					return &Error{"grading_variants", where}
				}
				keys[s] = true
			}
		}
	}
	for _, q := range d.Questions {
		if q.Revision.SHA256 != hashWithout(q, "revision") {
			return &Error{"revision_hash", d.QuizID + "/" + q.QuestionID}
		}
	}
	if d.Revision.SHA256 != hashWithout(d, "revision") {
		return &Error{"revision_hash", d.QuizID}
	}
	return nil
}
func ValidateCollection(drafts []Draft, schemaDir string) error {
	seen := map[string]bool{}
	for _, d := range drafts {
		if seen[d.QuizID] {
			return &Error{"duplicate_id", d.QuizID}
		}
		seen[d.QuizID] = true
		if e := ValidateDraft(d, filepath.Join(schemaDir, "draft-quiz.schema.json")); e != nil {
			return e
		}
	}
	return nil
}

// DraftFromBundle reconstructs the exact private revision input. Public question
// and quiz revisions intentionally identify the original private draft content.
func DraftFromBundle(b Bundle) Draft {
	d := Draft{Contract: b.Contract, State: "draft", QuizID: b.Quiz.QuizID, Revision: b.Quiz.Revision, Locale: b.Quiz.Locale, Questions: make([]Question, 0, len(b.Quiz.Questions))}
	for _, q := range b.Quiz.Questions {
		d.Questions = append(d.Questions, Question{QuestionID: q.QuestionID, Revision: q.Revision, Stem: q.Stem, Options: q.Options, Difficulty: q.Difficulty, Source: q.Source, Media: q.Media, AnswerKind: q.AnswerKind, Grading: b.PrivateGrading[q.QuestionID]})
	}
	return d
}
func ValidateBundle(b Bundle, schemaPath string) error {
	data, e := json.Marshal(b)
	if e != nil {
		return &Error{"encode", b.Quiz.QuizID}
	}
	if e = ValidateSchema(data, schemaPath, b.Quiz.QuizID); e != nil {
		return e
	}
	return validateBundleLinks(b)
}
func validateBundleLinks(b Bundle) error {
	if strings.TrimSpace(b.BundleVersion) == "" {
		return &Error{"required", b.Quiz.QuizID + "/bundle_version"}
	}
	for _, q := range b.Quiz.Questions {
		if q.QuizID != b.Quiz.QuizID {
			return &Error{"quiz_reference", b.Quiz.QuizID + "/" + q.QuestionID}
		}
		if _, ok := b.PrivateGrading[q.QuestionID]; !ok {
			return &Error{"grading_coverage", b.Quiz.QuizID + "/" + q.QuestionID}
		}
	}
	if len(b.PrivateGrading) != len(b.Quiz.Questions) {
		return &Error{"grading_coverage", b.Quiz.QuizID}
	}
	if e := validateDraftLinks(DraftFromBundle(b)); e != nil {
		return e
	}
	if b.BundleSHA256 != hashWithout(b, "bundle_sha256") {
		return &Error{"bundle_hash", b.Quiz.QuizID}
	}
	return nil
}

// Document is a validated local draft or controlled bundle. Raw JSON is schema
// checked before typed decoding, so unknown fields and nulls cannot disappear.
type Document struct {
	Draft  Draft
	Bundle *Bundle
}

func ReadDocument(path, schemaDir string) (Document, error) {
	data, e := os.ReadFile(path)
	if e != nil {
		return Document{}, &Error{"read", path}
	}
	raw, e := decodeJSON(data, path)
	if e != nil {
		return Document{}, e
	}
	obj, ok := raw.(map[string]any)
	if !ok {
		return Document{}, &Error{"schema_invalid", path}
	}
	name := "draft-quiz.schema.json"
	_, bundle := obj["bundle_version"]
	if bundle {
		name = "published-bundle.schema.json"
	}
	if e = ValidateSchema(data, filepath.Join(schemaDir, name), path); e != nil {
		return Document{}, e
	}
	var result Document
	if bundle {
		var b Bundle
		if e = json.Unmarshal(data, &b); e == nil {
			e = validateBundleLinks(b)
		}
		result = Document{Draft: DraftFromBundle(b), Bundle: &b}
	} else {
		var d Draft
		if e = json.Unmarshal(data, &d); e == nil {
			e = validateDraftLinks(d)
		}
		result.Draft = d
	}
	if e != nil {
		code := Code(e)
		if code == "" {
			code = "schema_invalid"
		}
		return Document{}, &Error{code, path + "#" + errorLocation(e)}
	}
	return result, nil
}
func errorLocation(e error) string {
	if ce, ok := e.(*Error); ok {
		return ce.Path
	}
	return ""
}

func Build(d Draft, version, publishedAt string, schemaDirs ...string) (Bundle, error) {
	if strings.TrimSpace(version) == "" {
		return Bundle{}, &Error{"build_input", d.QuizID}
	}
	if _, e := time.Parse(time.RFC3339, publishedAt); e != nil {
		return Bundle{}, &Error{"published_at", d.QuizID}
	}
	dir := DefaultSchemas
	if len(schemaDirs) > 0 {
		dir = schemaDirs[0]
	}
	if e := ValidateDraft(d, filepath.Join(dir, "draft-quiz.schema.json")); e != nil {
		return Bundle{}, e
	}
	b := Bundle{Contract: d.Contract, BundleVersion: version, PublishedAt: publishedAt, Quiz: PublicQuiz{QuizID: d.QuizID, Revision: d.Revision, Locale: d.Locale}, PrivateGrading: map[string]Grading{}}
	for _, q := range d.Questions {
		b.Quiz.Questions = append(b.Quiz.Questions, PublicQuestion{QuizID: d.QuizID, QuestionID: q.QuestionID, Revision: q.Revision, Stem: q.Stem, Options: q.Options, Difficulty: q.Difficulty, Source: q.Source, Media: q.Media, AnswerKind: q.AnswerKind})
		b.PrivateGrading[q.QuestionID] = q.Grading
	}
	b.BundleSHA256 = hashWithout(b, "bundle_sha256")
	if e := ValidateBundle(b, filepath.Join(dir, "published-bundle.schema.json")); e != nil {
		return Bundle{}, e
	}
	return b, nil
}
