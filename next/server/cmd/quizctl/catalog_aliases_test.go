package main

import (
	"testing"

	"quiz_master/next/server/internal/attempts"
)

func TestCatalogOmitsLegacyAliasAndRetainsDerivedTarget(t *testing.T) {
	packs := []auditPack{{CanonicalID: "legacy-short", Questions: 3}, {CanonicalID: "derived-twenty", Questions: attempts.MinimumAttemptQuestions}}
	playable, err := catalogPlayablePacks(packs, map[string]string{"legacy-short": "derived-twenty"})
	if err != nil {
		t.Fatal(err)
	}
	if len(playable) != 1 || playable[0].CanonicalID != "derived-twenty" {
		t.Fatalf("playable catalog = %+v", playable)
	}
}

func TestCatalogAliasValidationAndMinimumEligibility(t *testing.T) {
	base := []auditPack{
		{CanonicalID: "legacy", Questions: 3},
		{CanonicalID: "target", Questions: attempts.MinimumAttemptQuestions},
		{CanonicalID: "short", Questions: attempts.MinimumAttemptQuestions - 1},
	}
	for name, aliases := range map[string]map[string]string{
		"missing target": {"legacy": "missing"},
		"self":           {"legacy": "legacy"},
		"chain":          {"legacy": "target", "target": "short"},
	} {
		t.Run(name, func(t *testing.T) {
			if _, err := catalogPlayablePacks(base, aliases); err == nil {
				t.Fatal("catalog accepted invalid aliases")
			}
		})
	}
	playable, err := catalogPlayablePacks(base, map[string]string{"not-in-this-fixture": "also-absent"})
	if err != nil {
		t.Fatalf("unrelated source alias rejected fixture: %v", err)
	}
	if len(playable) != 1 || playable[0].CanonicalID != "target" {
		t.Fatalf("playable catalog = %+v; want only minimum-eligible target", playable)
	}
}
