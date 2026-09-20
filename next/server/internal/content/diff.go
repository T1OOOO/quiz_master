package content

import (
	"fmt"
	"sort"
	"strings"
)

// Diff emits IDs/revisions only. Private values and prose never enter output.
func Diff(before, after Draft) string {
	lines := []string{}
	if before.QuizID != after.QuizID {
		lines = append(lines, "quiz removed: "+before.QuizID, "quiz added: "+after.QuizID)
	} else if before.Revision != after.Revision {
		lines = append(lines, fmt.Sprintf("quiz changed: %s revision %d:%s -> %d:%s", after.QuizID, before.Revision.Number, before.Revision.SHA256, after.Revision.Number, after.Revision.SHA256))
	}
	old, new := map[string]Revision{}, map[string]Revision{}
	for _, q := range before.Questions {
		old[q.QuestionID] = q.Revision
	}
	for _, q := range after.Questions {
		new[q.QuestionID] = q.Revision
	}
	for id, rev := range old {
		if nr, ok := new[id]; !ok {
			lines = append(lines, "question removed: "+id)
		} else if nr != rev {
			lines = append(lines, fmt.Sprintf("question changed: %s revision %d:%s -> %d:%s", id, rev.Number, rev.SHA256, nr.Number, nr.SHA256))
		}
	}
	for id := range new {
		if _, ok := old[id]; !ok {
			lines = append(lines, "question added: "+id)
		}
	}
	if len(lines) == 0 {
		return "no changes"
	}
	sort.Strings(lines)
	return strings.Join(lines, "\n")
}
func DiffDocuments(before, after Document) string {
	result := Diff(before.Draft, after.Draft)
	if (before.Bundle == nil) != (after.Bundle == nil) {
		if result == "no changes" {
			result = ""
		}
		return strings.TrimSpace(result + "\nartifact kind changed")
	}
	if before.Bundle != nil && before.Bundle.BundleSHA256 != after.Bundle.BundleSHA256 {
		if result == "no changes" {
			result = ""
		}
		return strings.TrimSpace(result + "\nbundle revision changed: " + before.Bundle.BundleSHA256 + " -> " + after.Bundle.BundleSHA256)
	}
	return result
}
