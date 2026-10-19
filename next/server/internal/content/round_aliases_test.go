package content

import "testing"

func TestPlayableQuizIDResolvesExactlyOneInjectedAlias(t *testing.T) {
	aliases := map[string]string{"legacy-short": "derived-twenty"}
	if got := playableQuizID("legacy-short", aliases); got != "derived-twenty" {
		t.Fatalf("legacy alias = %q", got)
	}
	if got := playableQuizID("derived-twenty", aliases); got != "derived-twenty" {
		t.Fatalf("target changed = %q", got)
	}
}
