package attempts

import (
	"context"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestControlledBundleFailsClosedBeforeDatabaseAccess(t *testing.T) {
	raw, err := os.ReadFile("../../../content/home-alone-1-part-1/bundle.json")
	if err != nil {
		t.Fatal(err)
	}
	for name, data := range map[string][]byte{
		"unknown":                append([]byte(`{"unknown":true,`), raw[1:]...),
		"duplicate":              append([]byte(`{"contract":"quiz-contract/v1",`), raw[1:]...),
		"trailing":               append(append([]byte(nil), raw...), []byte(`{}`)...),
		"wrong hash":             []byte(strings.Replace(string(raw), "6c7754aa9b142d8657bac1bb65f0536d30364d262ef109315c4b9356ee512b95", strings.Repeat("0", 64), 1)),
		"wrong private revision": []byte(strings.Replace(string(raw), `"correct_option_id":"q-ha1-p1-1-opt-1"`, `"correct_option_id":"q-ha1-p1-1-opt-2"`, 1)),
	} {
		t.Run(name, func(t *testing.T) {
			path := filepath.Join(t.TempDir(), "bundle.json")
			if err := os.WriteFile(path, data, 0600); err != nil {
				t.Fatal(err)
			}
			if _, err := NewService(context.Background(), nil, path, "../../../contracts/quiz-contract/v1/schemas", 30*time.Minute, Options{}); err == nil {
				t.Fatal("invalid controlled bundle accepted")
			}
		})
	}
	if _, err := NewService(context.Background(), nil, "../../../content/home-alone-1-part-1/draft.json", "../../../contracts/quiz-contract/v1/schemas", 30*time.Minute, Options{}); err == nil {
		t.Fatal("private draft used as bundle")
	}
}
