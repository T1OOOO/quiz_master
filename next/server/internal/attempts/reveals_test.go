package attempts

import (
	"encoding/json"
	"testing"

	"quiz_master/next/server/internal/content"
)

func TestBuildRevealUsesOnlyContractDisplayAnswers(t *testing.T) {
	revision := content.Revision{Number: 3, SHA256: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"}
	questions := []content.PublicQuestion{
		{QuizID: "quiz-one", QuestionID: "question-single", Revision: revision, AnswerKind: "single_choice", Options: []content.Option{{OptionID: "option-one", Text: "One"}, {OptionID: "option-two", Text: "Two"}}},
		{QuizID: "quiz-one", QuestionID: "question-multi", Revision: revision, AnswerKind: "multiple_choice", Options: []content.Option{{OptionID: "option-one", Text: "One"}, {OptionID: "option-two", Text: "Two"}}},
		{QuizID: "quiz-one", QuestionID: "question-text", Revision: revision, AnswerKind: "normalized_text"},
	}
	b := content.Bundle{Quiz: content.PublicQuiz{QuizID: "quiz-one", Questions: questions}, PrivateGrading: map[string]content.Grading{
		"question-single": {CorrectOptionID: "option-two"},
		"question-multi":  {CorrectOptionIDs: []string{"option-two", "option-one"}},
		"question-text":   {AcceptedVariants: []string{"First display", "private alternate"}},
	}}
	explanations := map[string]string{"question-single": "Single explanation", "question-multi": "Multi explanation", "question-text": "Text explanation"}
	wants := map[string]string{
		"question-single": `{"quiz_id":"quiz-one","question_id":"question-single","question_revision":{"number":3,"sha256":"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"},"correct_answer":{"option_id":"option-two","text":"Two"},"explanation":"Single explanation"}`,
		"question-multi":  `{"quiz_id":"quiz-one","question_id":"question-multi","question_revision":{"number":3,"sha256":"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"},"correct_answer":{"option_ids":["option-two","option-one"],"text":"Two, One"},"explanation":"Multi explanation"}`,
		"question-text":   `{"quiz_id":"quiz-one","question_id":"question-text","question_revision":{"number":3,"sha256":"0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"},"correct_answer":{"text":"First display"},"explanation":"Text explanation"}`,
	}
	for _, q := range questions {
		t.Run(q.QuestionID, func(t *testing.T) {
			reveal, err := buildReveal(b, explanations, q.QuestionID)
			if err != nil {
				t.Fatal(err)
			}
			raw, err := json.Marshal(reveal)
			if err != nil {
				t.Fatal(err)
			}
			if string(raw) != wants[q.QuestionID] {
				t.Fatalf("reveal = %s", raw)
			}
			if err = content.ValidateSchema(raw, "../../../contracts/quiz-contract/v1/schemas/reveal.schema.json", "reveal"); err != nil {
				t.Fatal(err)
			}
		})
	}
}

func TestBuildRevealRejectsIncompletePrivateInputs(t *testing.T) {
	q := content.PublicQuestion{QuizID: "quiz-one", QuestionID: "question-one", Revision: content.Revision{Number: 1, SHA256: "0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef"}, AnswerKind: "single_choice", Options: []content.Option{{OptionID: "option-one", Text: "One"}}}
	b := content.Bundle{Quiz: content.PublicQuiz{QuizID: "quiz-one", Questions: []content.PublicQuestion{q}}, PrivateGrading: map[string]content.Grading{"question-one": {CorrectOptionID: "missing-option"}}}
	if _, err := buildReveal(b, map[string]string{"question-one": "Explanation"}, q.QuestionID); err == nil {
		t.Fatal("unknown correct option accepted")
	}
	b.PrivateGrading[q.QuestionID] = content.Grading{CorrectOptionID: "option-one"}
	if _, err := buildReveal(b, map[string]string{"question-one": " "}, q.QuestionID); err == nil {
		t.Fatal("blank explanation accepted")
	}
	if _, err := buildReveal(b, map[string]string{"question-one": "Explanation"}, "question-missing"); err == nil {
		t.Fatal("unknown question accepted")
	}
}
