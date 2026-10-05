package content

import (
	"os"
	"regexp"
	"strings"
)

var taxonomyIDPattern = regexp.MustCompile(`^[a-z][a-z0-9-]*:[a-z][a-z0-9-]*$`)
var taxonomySHA256Pattern = regexp.MustCompile(`^[0-9a-f]{64}$`)

type TaxonomyTag struct {
	ID         string   `json:"id"`
	Facet      string   `json:"facet"`
	PlayerSafe bool     `json:"player_safe"`
	ParentIDs  []string `json:"parent_ids"`
}
type Taxonomy struct {
	ID     string
	SHA256 string
	Tags   map[string]TaxonomyTag
}

// LoadTaxonomy validates the frozen dictionary identity before it is used for
// imports or publication. Stored bundles intentionally do not call this path.
func LoadTaxonomy(path string) (*Taxonomy, error) {
	b, err := os.ReadFile(path)
	if err != nil {
		return nil, &Error{"taxonomy_read", path}
	}
	v, err := decodeJSON(b, path)
	if err != nil {
		return nil, &Error{"taxonomy_invalid", path}
	}
	root, ok := v.(map[string]any)
	if !ok {
		return nil, &Error{"taxonomy_invalid", path}
	}
	if err = allowed(root, "schema_version taxonomy_id facets tags collections authorities visibility_policy taxonomy_sha256", path); err != nil {
		return nil, &Error{"taxonomy_invalid", path}
	}
	version, vok := nonblank(root["schema_version"])
	id, iok := nonblank(root["taxonomy_id"])
	want, hok := nonblank(root["taxonomy_sha256"])
	if !vok || version != "qm-taxonomy/v1" || !iok || !hok || !taxonomySHA256Pattern.MatchString(want) {
		return nil, &Error{"taxonomy_invalid", path}
	}
	delete(root, "taxonomy_sha256")
	if got := sum(root); got != want {
		return nil, &Error{"taxonomy_hash", path}
	}
	facets, ok := root["facets"].([]any)
	if !ok || len(facets) == 0 {
		return nil, &Error{"taxonomy_invalid", path}
	}
	facetSet := map[string]bool{}
	for _, entry := range facets {
		item, ok := entry.(map[string]any)
		name, ok := nonblank(item["id"])
		if !ok || facetSet[name] {
			return nil, &Error{"taxonomy_invalid", path}
		}
		facetSet[name] = true
	}
	tags, ok := root["tags"].([]any)
	if !ok || len(tags) == 0 {
		return nil, &Error{"taxonomy_invalid", path}
	}
	taxonomy := &Taxonomy{ID: id, SHA256: want, Tags: map[string]TaxonomyTag{}}
	for _, entry := range tags {
		item, ok := entry.(map[string]any)
		if !ok {
			return nil, &Error{"taxonomy_invalid", path}
		}
		tagID, idOK := nonblank(item["id"])
		facet, facetOK := nonblank(item["facet"])
		_, labelRUOK := nonblank(item["label_ru"])
		_, labelENOK := nonblank(item["label_en"])
		_, aliasesRUOK := taxonomyAliases(item["aliases_ru"])
		_, aliasesENOK := taxonomyAliases(item["aliases_en"])
		playerSafe, safeOK := item["player_safe"].(bool)
		parents, parentsOK := taxonomyStringIDs(item["parent_ids"])
		if !idOK || !taxonomyIDPattern.MatchString(tagID) || !facetOK || !facetSet[facet] || !labelRUOK || !labelENOK || !aliasesRUOK || !aliasesENOK || !safeOK || !parentsOK || taxonomy.Tags[tagID].ID != "" || taxonomyFacet(tagID) != facet || (privateFacet(facet) && playerSafe) {
			return nil, &Error{"taxonomy_invalid", path}
		}
		// Prefixes are identifiers, not facets: skill:* belongs to knowledge_skill.
		taxonomy.Tags[tagID] = TaxonomyTag{ID: tagID, Facet: facet, PlayerSafe: playerSafe, ParentIDs: parents}
	}
	for _, tag := range taxonomy.Tags {
		for _, parent := range tag.ParentIDs {
			if taxonomy.Tags[parent].ID == "" {
				return nil, &Error{"taxonomy_reference", path}
			}
		}
	}
	visiting, visited := map[string]bool{}, map[string]bool{}
	var visit func(string) bool
	visit = func(id string) bool {
		if visiting[id] {
			return false
		}
		if visited[id] {
			return true
		}
		visiting[id] = true
		for _, parent := range taxonomy.Tags[id].ParentIDs {
			if !visit(parent) {
				return false
			}
		}
		delete(visiting, id)
		visited[id] = true
		return true
	}
	for id := range taxonomy.Tags {
		if !visit(id) {
			return nil, &Error{"taxonomy_cycle", path}
		}
	}
	if collections, exists := root["collections"]; exists {
		if err = validateTaxonomyCollections(collections, taxonomy, path); err != nil {
			return nil, err
		}
	}
	return taxonomy, nil
}

func taxonomyAliases(v any) ([]string, bool) {
	values, ok := v.([]any)
	if !ok {
		return nil, false
	}
	seen := map[string]bool{}
	out := make([]string, len(values))
	for i, value := range values {
		alias, ok := nonblank(value)
		if !ok || seen[alias] {
			return nil, false
		}
		seen[alias] = true
		out[i] = alias
	}
	return out, true
}

func taxonomyFacet(id string) string {
	prefix, _, _ := strings.Cut(id, ":")
	switch prefix {
	case "skill":
		return "knowledge_skill"
	case "ingredient-family":
		return "ingredient"
	}
	return prefix
}

func privateFacet(facet string) bool {
	switch facet {
	case "country", "place", "ingredient", "cuisine", "person":
		return true
	}
	return false
}

func taxonomyStringIDs(v any) ([]string, bool) {
	values, ok := v.([]any)
	if !ok {
		return nil, false
	}
	out := make([]string, len(values))
	seen := map[string]bool{}
	for i, value := range values {
		id, ok := nonblank(value)
		if !ok || !taxonomyIDPattern.MatchString(id) || seen[id] {
			return nil, false
		}
		seen[id] = true
		out[i] = id
	}
	return out, true
}
func validateTaxonomyCollections(v any, taxonomy *Taxonomy, path string) error {
	collections, ok := v.([]any)
	if !ok {
		return &Error{"taxonomy_invalid", path}
	}
	collectionIDs := map[string]bool{}
	for _, value := range collections {
		collection, ok := value.(map[string]any)
		if !ok {
			return &Error{"taxonomy_invalid", path}
		}
		id, ok := nonblank(collection["id"])
		if !ok || !strings.HasPrefix(id, "collection:") || collectionIDs[id] {
			return &Error{"taxonomy_invalid", path}
		}
		collectionIDs[id] = true
		for _, key := range []string{"all_tag_ids", "any_tag_ids", "excluded_tag_ids"} {
			ids, ok := taxonomyStringIDs(collection[key])
			if !ok {
				return &Error{"taxonomy_invalid", path}
			}
			for _, id := range ids {
				if taxonomy.Tags[id].ID == "" {
					return &Error{"taxonomy_reference", path}
				}
			}
		}
	}
	return nil
}

func validateDifficulty(difficulty string, level *int, path string) error {
	if level == nil {
		return nil // Existing canonical archives may retain a known band alone.
	}
	if *level < 1 || *level > 10 || difficulty == "unknown" || difficultyBand(*level) != difficulty {
		return &Error{"difficulty", path}
	}
	return nil
}
func difficultyBand(level int) string {
	switch {
	case level <= 3:
		return "easy"
	case level <= 6:
		return "medium"
	case level <= 8:
		return "hard"
	default:
		return "nightmare"
	}
}
func validateTagIDs(ids []string, path string) error {
	for i, id := range ids {
		if !taxonomyIDPattern.MatchString(id) || (i > 0 && ids[i-1] >= id) {
			return &Error{"tag_ids", path}
		}
	}
	return nil
}
func validateTaxonomyLinks(d Draft, taxonomy *Taxonomy) error {
	if taxonomy == nil {
		return &Error{"taxonomy_required", d.QuizID}
	}
	if d.TaxonomyRef == nil || d.TaxonomyRef.TaxonomyID != taxonomy.ID || d.TaxonomyRef.TaxonomySHA256 != taxonomy.SHA256 {
		return &Error{"taxonomy_reference", d.QuizID}
	}
	for _, q := range d.Questions {
		where := d.QuizID + "/" + q.QuestionID
		if err := validateTagIDs(q.EditorialTagIDs, where); err != nil {
			return err
		}
		if err := validateTagIDs(q.ContextTagIDs, where); err != nil {
			return err
		}
		editorial := map[string]bool{}
		for _, id := range q.EditorialTagIDs {
			if taxonomy.Tags[id].ID == "" {
				return &Error{"tag_unknown", where}
			}
			editorial[id] = true
		}
		for _, id := range q.ContextTagIDs {
			tag := taxonomy.Tags[id]
			if tag.ID == "" {
				return &Error{"tag_unknown", where}
			}
			if !editorial[id] {
				return &Error{"context_tag_subset", where}
			}
			if !tag.PlayerSafe || privateFacet(tag.Facet) {
				return &Error{"context_tag_unsafe", where}
			}
		}
	}
	return nil
}

func hasAnnotations(d Draft) bool {
	if d.TaxonomyRef != nil {
		return true
	}
	for _, q := range d.Questions {
		if len(q.EditorialTagIDs) != 0 || len(q.ContextTagIDs) != 0 {
			return true
		}
	}
	return false
}
func HasAnnotations(d Draft) bool { return hasAnnotations(d) }
