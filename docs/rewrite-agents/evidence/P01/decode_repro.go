package main

import (
	"encoding/json"
	"fmt"
	"os"

	quizdomain "quiz_master/internal/quiz/domain"
)

type sourceQuestion struct {
	CorrectAnswer int             `json:"correct_answer"`
	CorrectMulti  json.RawMessage `json:"correct_multi"`
}

type sourceQuiz struct {
	Questions []sourceQuestion `json:"questions"`
}

func main() {
	if len(os.Args) != 2 {
		panic("usage: go run decode_repro.go decode_fixture.json")
	}
	raw, err := os.ReadFile(os.Args[1])
	if err != nil {
		panic(err)
	}
	var source sourceQuiz
	if err := json.Unmarshal(raw, &source); err != nil {
		panic(err)
	}
	var decoded quizdomain.Quiz
	if err := json.Unmarshal(raw, &decoded); err != nil {
		panic(err)
	}
	persisted, err := json.Marshal(decoded.Questions[0])
	if err != nil {
		panic(err)
	}
	fmt.Printf("source_correct_answer=%d\n", source.Questions[0].CorrectAnswer)
	fmt.Printf("source_correct_multi_present=%t\n", source.Questions[0].CorrectMulti != nil)
	fmt.Printf("decoded_correct_answer_index=%d\n", decoded.Questions[0].CorrectAnswerIndex)
	fmt.Printf("persisted_question_json=%s\n", persisted)
}
