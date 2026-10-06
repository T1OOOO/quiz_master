package content

import (
	"encoding/json"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
)

func taxonomyFixture(t *testing.T) *Taxonomy {
	t.Helper()
	v := map[string]any{
		"schema_version": "qm-taxonomy/v1",
		"taxonomy_id":    "test-tags-v1",
		"facets": []any{
			map[string]any{"id": "topic", "ru": "Тема", "en": "Topic", "cardinality": "1..n"},
			map[string]any{"id": "knowledge_skill", "ru": "Знание", "en": "Knowledge", "cardinality": "1..n"},
		},
		"tags": []any{
			map[string]any{"id": "topic:astronomy", "facet": "topic", "label_ru": "Астрономия", "label_en": "Astronomy", "aliases_ru": []any{}, "aliases_en": []any{}, "parent_ids": []any{}, "player_safe": true},
			map[string]any{"id": "skill:recall", "facet": "knowledge_skill", "label_ru": "Воспоминание", "label_en": "Recall", "aliases_ru": []any{}, "aliases_en": []any{}, "parent_ids": []any{}, "player_safe": false},
		},
		"collections": []any{},
	}
	v["taxonomy_sha256"] = sum(v)
	raw, err := json.Marshal(v)
	if err != nil {
		t.Fatal(err)
	}
	p := filepath.Join(t.TempDir(), "tags.v1.json")
	if err = os.WriteFile(p, raw, 0600); err != nil {
		t.Fatal(err)
	}
	taxonomy, err := LoadTaxonomy(p)
	if err != nil {
		t.Fatal(err)
	}
	return taxonomy
}

func TestImportRetainsExactDifficultyLevelAndFourBands(t *testing.T) {
	for level, wantBand := range map[int]string{1: "easy", 3: "easy", 4: "medium", 6: "medium", 7: "hard", 8: "hard", 9: "nightmare", 10: "nightmare"} {
		t.Run(wantBand, func(t *testing.T) {
			source := strings.Replace(legacyBase, `"correct_answer":2`, `"correct_answer":2,"difficulty":`+strconv.Itoa(level), 1)
			d, _, err := importText(t, source)
			if err != nil {
				t.Fatal(err)
			}
			q := d.Questions[0]
			if q.Difficulty != wantBand || q.DifficultyLevel == nil || *q.DifficultyLevel != level {
				t.Fatalf("level %d became %q/%v", level, q.Difficulty, q.DifficultyLevel)
			}
		})
	}
}

func TestAnnotatedImportRequiresDeclaredTaxonomyAndKeepsPrivateTagsPrivate(t *testing.T) {
	taxonomy := taxonomyFixture(t)
	level := 7
	source := strings.Replace(legacyBase, `"category":"C"`, `"category":"C","taxonomy_ref":{"taxonomy_id":"test-tags-v1","taxonomy_sha256":"`+taxonomy.SHA256+`"}`, 1)
	source = strings.Replace(source, `"correct_answer":2`, `"correct_answer":2,"difficulty":7,"editorial_tag_ids":["skill:recall","topic:astronomy"],"context_tag_ids":["topic:astronomy"]`, 1)
	p := filepath.Join(t.TempDir(), "annotated.json")
	if err := os.WriteFile(p, []byte(source), 0600); err != nil {
		t.Fatal(err)
	}
	if _, _, err := ImportWithTaxonomy(p, nil); Code(err) != "taxonomy_required" {
		t.Fatalf("annotated source without taxonomy = %v", err)
	}
	d, _, err := ImportWithTaxonomy(p, taxonomy)
	if err != nil {
		t.Fatal(err)
	}
	if d.TaxonomyRef == nil || d.Questions[0].DifficultyLevel == nil || *d.Questions[0].DifficultyLevel != level {
		t.Fatal("annotation was not retained")
	}
	b, err := BuildWithTaxonomy(d, "tags-v1", "2026-10-05T00:00:00Z", taxonomy, schemas)
	if err != nil {
		t.Fatal(err)
	}
	public, _ := json.Marshal(b.Quiz)
	if strings.Contains(string(public), "editorial_tag_ids") || strings.Contains(string(public), "skill:recall") {
		t.Fatalf("private tags leaked into public quiz: %s", public)
	}
	if got := b.Quiz.Questions[0].ContextTagIDs; len(got) != 1 || got[0] != "topic:astronomy" {
		t.Fatalf("safe context projection = %v", got)
	}
	if got := b.PrivateQuestionMetadata[d.Questions[0].QuestionID].EditorialTagIDs; len(got) != 2 {
		t.Fatalf("private metadata = %v", got)
	}
}

func TestTaxonomyRejectsPrefixFacetMismatchAndUnsafeContext(t *testing.T) {
	taxonomy := taxonomyFixture(t)
	if taxonomy.Tags["skill:recall"].Facet != "knowledge_skill" {
		t.Fatal("typed ID prefix was treated as its facet")
	}
	d := fixture(t)
	d.TaxonomyRef = &TaxonomyRef{TaxonomyID: taxonomy.ID, TaxonomySHA256: taxonomy.SHA256}
	d.Questions[0].DifficultyLevel = intPtr(7)
	d.Questions[0].Difficulty = "hard"
	d.Questions[0].EditorialTagIDs = []string{"skill:recall", "topic:astronomy"}
	d.Questions[0].ContextTagIDs = []string{"skill:recall"}
	Rehash(&d)
	if err := ValidateDraftWithTaxonomy(d, schemas, taxonomy); Code(err) != "context_tag_unsafe" {
		t.Fatalf("unsafe context accepted: %v", err)
	}
	// Link validation protects publication even when a caller assembled a
	// taxonomy in memory instead of calling LoadTaxonomy first.
	taxonomy = &Taxonomy{ID: "in-memory", SHA256: strings.Repeat("a", 64), Tags: map[string]TaxonomyTag{"country:it": {ID: "country:it", Facet: "country", PlayerSafe: true}}}
	d.TaxonomyRef = &TaxonomyRef{TaxonomyID: taxonomy.ID, TaxonomySHA256: taxonomy.SHA256}
	d.Questions[0].EditorialTagIDs = []string{"country:it"}
	d.Questions[0].ContextTagIDs = []string{"country:it"}
	Rehash(&d)
	if err := ValidateDraftWithTaxonomy(d, schemas, taxonomy); Code(err) != "context_tag_unsafe" {
		t.Fatalf("private in-memory context accepted: %v", err)
	}
}

func TestLoadTaxonomyRejectsRequiredFieldFacetAndVisibilityViolations(t *testing.T) {
	base := func() map[string]any {
		return map[string]any{"schema_version": "qm-taxonomy/v1", "taxonomy_id": "test-tags-v1", "facets": []any{map[string]any{"id": "topic"}, map[string]any{"id": "knowledge_skill"}, map[string]any{"id": "country"}}, "tags": []any{map[string]any{"id": "topic:astronomy", "facet": "topic", "label_ru": "Астрономия", "label_en": "Astronomy", "aliases_ru": []any{}, "aliases_en": []any{}, "parent_ids": []any{}, "player_safe": true}, map[string]any{"id": "skill:recall", "facet": "knowledge_skill", "label_ru": "Память", "label_en": "Recall", "aliases_ru": []any{}, "aliases_en": []any{}, "parent_ids": []any{}, "player_safe": false}, map[string]any{"id": "country:it", "facet": "country", "label_ru": "Италия", "label_en": "Italy", "aliases_ru": []any{}, "aliases_en": []any{}, "parent_ids": []any{}, "player_safe": false}}, "collections": []any{}}
	}
	write := func(t *testing.T, v map[string]any) string {
		t.Helper()
		v["taxonomy_sha256"] = sum(v)
		raw, err := json.Marshal(v)
		if err != nil {
			t.Fatal(err)
		}
		p := filepath.Join(t.TempDir(), "tags.v1.json")
		if err = os.WriteFile(p, raw, 0600); err != nil {
			t.Fatal(err)
		}
		return p
	}
	for name, mutate := range map[string]func(map[string]any){
		"missing label": func(v map[string]any) { delete(v["tags"].([]any)[0].(map[string]any), "label_en") },
		"blank alias":   func(v map[string]any) { v["tags"].([]any)[0].(map[string]any)["aliases_en"] = []any{""} },
		"duplicate alias": func(v map[string]any) {
			v["tags"].([]any)[0].(map[string]any)["aliases_en"] = []any{"astronomy", "astronomy"}
		},
		"prefix facet mismatch": func(v map[string]any) { v["tags"].([]any)[0].(map[string]any)["facet"] = "country" },
		"private facet safe":    func(v map[string]any) { v["tags"].([]any)[2].(map[string]any)["player_safe"] = true },
		"duplicate collection id": func(v map[string]any) {
			v["collections"] = []any{map[string]any{"id": "collection:one", "all_tag_ids": []any{}, "any_tag_ids": []any{}, "excluded_tag_ids": []any{}}, map[string]any{"id": "collection:one", "all_tag_ids": []any{}, "any_tag_ids": []any{}, "excluded_tag_ids": []any{}}}
		},
	} {
		t.Run(name, func(t *testing.T) {
			v := base()
			mutate(v)
			if _, err := LoadTaxonomy(write(t, v)); err == nil {
				t.Fatal("accepted malformed taxonomy")
			}
		})
	}
}

func TestLoadTaxonomyRealFixtureHashAndInventory(t *testing.T) {
	taxonomy, err := LoadTaxonomy(filepath.Join("..", "..", "..", "..", "metadata", "tags.v1.json"))
	if err != nil {
		t.Fatal(err)
	}
	if taxonomy.ID != "qm-tags-v1" || taxonomy.SHA256 != "07e4bbb5c7afcdab3b41a26dca1bf0ba9a830d5f776a98ebceeaeb2bd8356151" || len(taxonomy.Tags) != 425 {
		t.Fatalf("fixture identity/tags = %q/%q/%d", taxonomy.ID, taxonomy.SHA256, len(taxonomy.Tags))
	}
}

func intPtr(v int) *int { return &v }
