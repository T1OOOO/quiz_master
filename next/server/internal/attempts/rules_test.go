package attempts

import (
	"encoding/json"
	"strings"
	"testing"

	"quiz_master/next/server/internal/content"
)

func TestParticipantBoundary(t *testing.T) {
	for _, hex := range []string{strings.Repeat("0", 32), strings.Repeat("f", 32), "0123456789abcdef0123456789abcdef"} {
		external, err := ExternalParticipant("p_" + hex)
		if err != nil || external != "p-"+hex {
			t.Fatal("external conversion", err)
		}
		internal, err := InternalParticipant(external)
		if err != nil || internal != "p_"+hex {
			t.Fatal("internal conversion", err)
		}
	}
	for _, bad := range []string{"", "p_", "p-" + strings.Repeat("a", 32), "p_" + strings.Repeat("A", 32), "p_" + strings.Repeat("a", 31), "p_" + strings.Repeat("a", 33), "p_" + strings.Repeat("g", 32), " p_" + strings.Repeat("a", 32), "p_" + strings.Repeat("a", 32) + "\n"} {
		if _, err := ExternalParticipant(bad); err == nil {
			t.Errorf("accepted internal %q", bad)
		}
	}
	for _, bad := range []string{"", "p_" + strings.Repeat("a", 32), "p-" + strings.Repeat("A", 32), "p-" + strings.Repeat("a", 31), "p-" + strings.Repeat("a", 33), "p-" + strings.Repeat("g", 32), "p-" + strings.Repeat("a", 32) + "\n"} {
		if _, err := InternalParticipant(bad); err == nil {
			t.Errorf("accepted external %q", bad)
		}
	}
}

func TestTypedValidationAndServerScoring(t *testing.T) {
	options := []content.Option{{OptionID: "opt-one"}, {OptionID: "opt-two"}, {OptionID: "opt-three"}, {OptionID: "opt-four"}}
	for _, tt := range []struct {
		name, kind, raw string
		grading         content.Grading
		valid           bool
		score           int
	}{
		{"single correct", "single_choice", `{"option_id":"opt-two"}`, content.Grading{CorrectOptionID: "opt-two"}, true, 1},
		{"single wrong", "single_choice", `{"option_id":"opt-one"}`, content.Grading{CorrectOptionID: "opt-two"}, true, 0},
		{"forged option", "single_choice", `{"option_id":"opt-forged"}`, content.Grading{}, false, 0},
		{"wrong kind", "single_choice", `{"text":"opt-two"}`, content.Grading{}, false, 0},
		{"multi reverse", "multiple_choice", `{"option_ids":["opt-two","opt-one"]}`, content.Grading{CorrectOptionIDs: []string{"opt-one", "opt-two"}}, true, 1},
		{"multi partial", "multiple_choice", `{"option_ids":["opt-one"]}`, content.Grading{CorrectOptionIDs: []string{"opt-one", "opt-two"}}, true, 0},
		{"multi extra", "multiple_choice", `{"option_ids":["opt-one","opt-two","opt-three"]}`, content.Grading{CorrectOptionIDs: []string{"opt-one", "opt-two"}}, true, 0},
		{"multi duplicate", "multiple_choice", `{"option_ids":["opt-one","opt-one"]}`, content.Grading{}, false, 0},
		{"multi empty", "multiple_choice", `{"option_ids":[]}`, content.Grading{}, false, 0},
		{"multi forged", "multiple_choice", `{"option_ids":["opt-forged"]}`, content.Grading{}, false, 0},
		{"text unicode", "normalized_text", `{"text":"  STRASSE\tÉ  "}`, content.Grading{AcceptedVariants: []string{"Straße é"}}, true, 1},
		{"text wrong", "normalized_text", `{"text":"other"}`, content.Grading{AcceptedVariants: []string{"answer"}}, true, 0},
		{"text empty", "normalized_text", `{"text":""}`, content.Grading{AcceptedVariants: []string{"answer"}}, true, 0},
		{"mixed fields", "single_choice", `{"option_id":"opt-one","text":""}`, content.Grading{}, false, 0},
		{"missing", "single_choice", `{}`, content.Grading{}, false, 0},
		{"null", "single_choice", `{"option_id":null}`, content.Grading{}, false, 0},
	} {
		t.Run(tt.name, func(t *testing.T) {
			var a Answer
			if err := json.Unmarshal([]byte(tt.raw), &a); err != nil {
				t.Fatal(err)
			}
			q := content.PublicQuestion{AnswerKind: tt.kind, Options: options}
			err := validateAnswer(q, a)
			if (err == nil) != tt.valid {
				t.Fatalf("validation=%v want valid %v", err, tt.valid)
			}
			if tt.valid && score(q, tt.grading, a) != tt.score {
				t.Fatal("wrong server score")
			}
		})
	}
}

func TestDigestCanonicalPayload(t *testing.T) {
	text := "Straße < é\u2028"
	got, err := PayloadDigest("att-one", "p-one", AnswerRequest{QuestionID: "q-one", QuestionRevision: content.Revision{Number: 2, SHA256: strings.Repeat("a", 64)}, Answer: Answer{Text: &text}, IdempotencyKey: "excluded"})
	if err != nil {
		t.Fatal(err)
	}
	// Computed independently with Python's json.dumps(ensure_ascii=False,sort_keys=True,separators=(',',':')).
	if got != "74cf19484fe1d05bebf8e1cda48cc6c14ec81e8f15ebf1aa9f01f0276afd406f" {
		t.Fatalf("canonical digest %s", got)
	}
}

func TestSnapshotsArePinnedAndDoNotMutateCatalog(t *testing.T) {
	b := content.Bundle{Quiz: content.PublicQuiz{Questions: []content.PublicQuestion{{QuestionID: "q-one", Revision: content.Revision{Number: 1}, Options: []content.Option{{OptionID: "opt-one"}, {OptionID: "opt-two"}}}}}}
	snapshots, err := makeSnapshots(b, func(ids []string) error { ids[0], ids[1] = ids[1], ids[0]; return nil })
	if err != nil {
		t.Fatal(err)
	}
	if snapshots[0].OptionOrder[0] != "opt-two" || snapshots[0].PositionToOptionID["0"] != "opt-two" || b.Quiz.Questions[0].Options[0].OptionID != "opt-one" {
		t.Fatal("snapshot order/mapping mutated")
	}
	if _, err := makeSnapshots(b, func(ids []string) error { ids[0] = "forged"; return nil }); err == nil {
		t.Fatal("invalid shuffler permutation accepted")
	}
}
