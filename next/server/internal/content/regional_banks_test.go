package content

import (
	"bytes"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"os"
	"path/filepath"
	"reflect"
	"testing"
)

// The regional packs intentionally duplicate only the public learning prompt
// of their one world-wide source pack.  This guard keeps the partition useful
// without creating a second, silently diverging question bank.
func TestRegionalGeographyBanksPartitionWorldPacksWithoutAnswerDrift(t *testing.T) {
	root := filepath.Join("..", "..", "..", "..")
	type sourceSpec struct {
		path     string
		hash     string
		kind     string
		category string
	}
	type packSpec struct {
		region string
		path   string
		id     string
	}
	sources := []sourceSpec{
		{"quizzes/Preparation/prep_capitals_world.json", "696b25cec11a2c671e555f9b5c93a2b5250d075564527e431afbaec104cf6842", "capitals", "География/Столицы"},
		{"quizzes/Preparation/prep_flags_world.json", "52de3206a1a73786b978ceab485e96555b4d57dcb4ae72099d7c005890ca51f9", "flags", "География/Флаги"},
	}
	regions := []string{"europe", "africa", "americas", "asia-oceania"}

	for _, source := range sources {
		sourcePath := filepath.Join(root, source.path)
		bytes, err := os.ReadFile(sourcePath)
		if err != nil {
			t.Fatal(err)
		}
		if got := normalizedSourceSHA256(bytes); got != source.hash {
			t.Fatalf("source %s changed: %s", source.path, got)
		}
		var original regionalRawPack
		if err := json.Unmarshal(bytes, &original); err != nil {
			t.Fatal(err)
		}
		if len(original.Questions) != 195 {
			t.Fatalf("source %s has %d questions, want 195", source.path, len(original.Questions))
		}
		byID := make(map[string]map[string]any, len(original.Questions))
		for _, question := range original.Questions {
			if byID[question.ID] != nil {
				t.Fatalf("duplicate source question %q", question.ID)
			}
			byID[question.ID] = question.Raw
		}

		seen := map[string]bool{}
		for _, region := range regions {
			path := filepath.Join(root, "quizzes", "Preparation", "GeographyRegions", "prep_"+source.kind+"_"+region+".json")
			data, err := os.ReadFile(path)
			if err != nil {
				t.Fatal(err)
			}
			var derived regionalRawPack
			if err := json.Unmarshal(data, &derived); err != nil {
				t.Fatal(err)
			}
			if derived.ID != "prep-"+source.kind+"-"+region || derived.Category != source.category {
				t.Fatalf("%s has id/category %q/%q", path, derived.ID, derived.Category)
			}
			if len(derived.Questions) < 20 {
				t.Fatalf("%s has only %d questions", path, len(derived.Questions))
			}
			for _, question := range derived.Questions {
				prefix := source.kind + "-" + region + "-"
				if len(question.ID) <= len(prefix) || question.ID[:len(prefix)] != prefix {
					t.Fatalf("%s has non-regional question id %q", path, question.ID)
				}
				sourceID := question.ID[len(prefix):]
				originalQuestion, ok := byID[sourceID]
				if !ok || seen[sourceID] {
					t.Fatalf("%s has missing or repeated source question %q", path, sourceID)
				}
				seen[sourceID] = true
				want := cloneQuestion(t, originalQuestion)
				want["id"] = question.ID
				if !reflect.DeepEqual(question.Raw, want) {
					t.Fatalf("%s question %q differs from source beyond its id", path, question.ID)
				}
				answer, ok := number(question.Raw["correct_answer"])
				if !ok {
					t.Fatalf("%s question %q has no numeric correct_answer", path, question.ID)
				}
				options, ok := question.Raw["options"].([]any)
				if !ok || answer < 0 || answer >= len(options) {
					t.Fatalf("%s question %q has invalid correct_answer", path, question.ID)
				}
			}
		}
		if len(seen) != len(original.Questions) {
			t.Fatalf("%s partition has %d questions, want %d", source.path, len(seen), len(original.Questions))
		}
	}
}

func TestRegionalWorldSourceHashNormalizesCRLFButRejectsContentMutation(t *testing.T) {
	lf := []byte("{\n  \"id\": \"source\"\n}\n")
	crlf := bytes.ReplaceAll(lf, []byte("\n"), []byte("\r\n"))
	if got, want := normalizedSourceSHA256(crlf), normalizedSourceSHA256(lf); got != want {
		t.Fatalf("CRLF hash %s, want LF hash %s", got, want)
	}

	mutated := bytes.Replace(lf, []byte("source"), []byte("changed"), 1)
	if normalizedSourceSHA256(mutated) == normalizedSourceSHA256(lf) {
		t.Fatal("source hash accepted a content mutation")
	}
}

type regionalRawPack struct {
	ID        string                `json:"id"`
	Category  string                `json:"category"`
	Questions []regionalRawQuestion `json:"questions"`
}

type regionalRawQuestion struct {
	ID  string
	Raw map[string]any
}

func (q *regionalRawQuestion) UnmarshalJSON(data []byte) error {
	if err := json.Unmarshal(data, &q.Raw); err != nil {
		return err
	}
	id, _ := q.Raw["id"].(string)
	q.ID = id
	return nil
}

func cloneQuestion(t *testing.T, question map[string]any) map[string]any {
	t.Helper()
	data, err := json.Marshal(question)
	if err != nil {
		t.Fatal(err)
	}
	var clone map[string]any
	if err = json.Unmarshal(data, &clone); err != nil {
		t.Fatal(err)
	}
	return clone
}

func number(value any) (int, bool) {
	valueFloat, ok := value.(float64)
	return int(valueFloat), ok && valueFloat == float64(int(valueFloat))
}

func sha256hex(data []byte) string {
	sum := sha256.Sum256(data)
	return hex.EncodeToString(sum[:])
}

func normalizedSourceSHA256(data []byte) string {
	return sha256hex(bytes.ReplaceAll(data, []byte("\r\n"), []byte("\n")))
}
