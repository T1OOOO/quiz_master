// quizctl operates on local, controlled private content only.
package main

import (
	"bytes"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"quiz_master/next/server/internal/attempts"
	"quiz_master/next/server/internal/content"
)

func main() { os.Exit(run(os.Args[1:], os.Stdout, os.Stderr)) }

// Exit contract: 0 successful/no semantic differences; 1 differences; 2 error.
func run(args []string, out, errOut io.Writer) int {
	fail := func(e error) int { fmt.Fprintln(errOut, "quizctl:", e); return 2 }
	usage := func() int {
		return fail(&content.Error{Kind: "usage", Path: "quizctl audit|catalog|import|validate|build|diff (see next/content/README.md)"})
	}
	if len(args) == 0 {
		return usage()
	}
	command := args[0]
	fs := flag.NewFlagSet(command, flag.ContinueOnError)
	fs.SetOutput(io.Discard)
	schemaDir := fs.String("schemas", content.DefaultSchemas, "local accepted schema directory")
	taxonomyPath := fs.String("taxonomy", "", "optional frozen taxonomy dictionary for annotated content")
	var in, outPath, before, after, version, publishedAt *string
	var force *bool
	var withDifficulty *bool
	switch command {
	case "catalog", "import", "build":
		in = fs.String("in", "", "input file")
		outPath = fs.String("out", "", "import directory or bundle file")
		force = fs.Bool("force", false, "explicit overwrite")
		if command == "catalog" {
			withDifficulty = fs.Bool("with-difficulty", false, "include public question counts by difficulty band")
		}
		if command == "build" {
			version = fs.String("version", "", "explicit bundle version")
			publishedAt = fs.String("published-at", "", "RFC3339 publication timestamp")
		}
	case "audit", "validate":
		in = fs.String("in", "", "draft or controlled bundle (additional paths may follow)")
	case "diff":
		before = fs.String("before", "", "original draft or controlled bundle")
		after = fs.String("after", "", "new draft or controlled bundle")
	default:
		return usage()
	}
	if fs.Parse(args[1:]) != nil {
		return usage()
	}
	if command != "validate" && fs.NArg() != 0 {
		return usage()
	}
	switch command {
	case "catalog":
		if *in == "" || *outPath == "" {
			return usage()
		}
		taxonomy, e := loadTaxonomy(*taxonomyPath)
		if e != nil {
			return fail(e)
		}
		// Reuse strict whole-corpus validation and collision reconciliation.
		// Never export audit rows directly: future audit fields may be private.
		var checked bytes.Buffer
		if e := auditWithTaxonomy(*in, *schemaDir, taxonomy, &checked); e != nil {
			return fail(e)
		}
		var report struct {
			Packs []auditPack `json:"packs"`
		}
		if e := json.Unmarshal(checked.Bytes(), &report); e != nil {
			return fail(e)
		}
		playable, e := catalogPlayablePacks(report.Packs, content.RoundAliases)
		if e != nil {
			return fail(e)
		}
		type metadata struct {
			QuizID           string         `json:"quiz_id"`
			Title            string         `json:"title"`
			Description      string         `json:"description"`
			Category         string         `json:"category"`
			Questions        int            `json:"questions_count"`
			DifficultyCounts map[string]int `json:"difficulty_counts,omitempty"`
		}
		packs := make([]metadata, 0, len(playable))
		for _, p := range playable {
			pack := metadata{QuizID: p.CanonicalID, Title: p.Title, Description: p.Description, Category: p.Category, Questions: p.Questions}
			if *withDifficulty {
				draft, _, e := content.ImportWithTaxonomy(p.Path, taxonomy)
				if e != nil {
					return fail(e)
				}
				counts, e := catalogDifficultyCounts(draft)
				if e != nil {
					return fail(e)
				}
				pack.DifficultyCounts = counts
			}
			packs = append(packs, pack)
		}
		if e := content.WriteJSON(*outPath, packs, *force); e != nil {
			return fail(e)
		}
		fmt.Fprintf(out, "catalog: %d packs\n", len(packs))
	case "audit":
		if *in == "" {
			return usage()
		}
		taxonomy, e := loadTaxonomy(*taxonomyPath)
		if e != nil {
			return fail(e)
		}
		if e := auditWithTaxonomy(*in, *schemaDir, taxonomy, out); e != nil {
			return fail(e)
		}
	case "import":
		if *in == "" || *outPath == "" {
			return usage()
		}
		for _, name := range []string{"draft.json", "manifest.json"} {
			if samePath(*in, filepath.Join(*outPath, name)) {
				return fail(&content.Error{Kind: "output_path", Path: *outPath})
			}
		}
		taxonomy, e := loadTaxonomy(*taxonomyPath)
		if e != nil {
			return fail(e)
		}
		d, m, e := content.ImportWithTaxonomy(*in, taxonomy)
		if e != nil {
			return fail(e)
		}
		if e = content.ValidateDraft(d, filepath.Join(*schemaDir, "draft-quiz.schema.json")); e != nil {
			return fail(e)
		}
		if e = content.WriteFiles(*outPath, map[string]any{"draft.json": d, "manifest.json": m}, *force); e != nil {
			return fail(e)
		}
		fmt.Fprintf(out, "imported %s: %d questions; source_sha256 %s\n", d.QuizID, len(d.Questions), m.SourceSHA256)
	case "validate":
		paths := fs.Args()
		if *in != "" {
			paths = append([]string{*in}, paths...)
		}
		if len(paths) == 0 {
			return usage()
		}
		seen := map[string]bool{}
		taxonomy, e := loadTaxonomy(*taxonomyPath)
		if e != nil {
			return fail(e)
		}
		for _, p := range paths {
			doc, e := content.ReadDocument(p, *schemaDir)
			if e != nil {
				return fail(e)
			}
			if taxonomy != nil {
				if doc.Bundle != nil {
					e = content.ValidateBundleWithTaxonomy(*doc.Bundle, *schemaDir, taxonomy)
				} else {
					e = content.ValidateDraftWithTaxonomy(doc.Draft, *schemaDir, taxonomy)
				}
				if e != nil {
					return fail(e)
				}
			}
			if seen[doc.Draft.QuizID] {
				return fail(&content.Error{Kind: "duplicate_id", Path: p + "#" + doc.Draft.QuizID})
			}
			seen[doc.Draft.QuizID] = true
			fmt.Fprintf(out, "valid %s: %d questions\n", doc.Draft.QuizID, len(doc.Draft.Questions))
		}
	case "build":
		if *in == "" || *outPath == "" || *version == "" || *publishedAt == "" {
			return usage()
		}
		if samePath(*in, *outPath) {
			return fail(&content.Error{Kind: "output_path", Path: *outPath})
		}
		doc, e := content.ReadDocument(*in, *schemaDir)
		if e != nil {
			return fail(e)
		}
		if doc.Bundle != nil {
			return fail(&content.Error{Kind: "build_input", Path: *in})
		}
		taxonomy, e := loadTaxonomy(*taxonomyPath)
		if e != nil {
			return fail(e)
		}
		b, e := content.BuildWithTaxonomy(doc.Draft, *version, *publishedAt, taxonomy, *schemaDir)
		if e != nil {
			return fail(e)
		}
		if e = content.WriteJSON(*outPath, b, *force); e != nil {
			return fail(e)
		}
		fmt.Fprintf(out, "built %s: %d questions; bundle_sha256 %s\n", b.Quiz.QuizID, len(b.Quiz.Questions), b.BundleSHA256)
	case "diff":
		if *before == "" || *after == "" {
			return usage()
		}
		a, e := content.ReadDocument(*before, *schemaDir)
		if e != nil {
			return fail(e)
		}
		b, e := content.ReadDocument(*after, *schemaDir)
		if e != nil {
			return fail(e)
		}
		summary := content.DiffDocuments(a, b)
		fmt.Fprintln(out, summary)
		if summary != "no changes" {
			return 1
		}
	}
	return 0
}

func catalogDifficultyCounts(draft content.Draft) (map[string]int, error) {
	counts := map[string]int{"easy": 0, "medium": 0, "hard": 0, "nightmare": 0, "unknown": 0}
	for _, question := range draft.Questions {
		if _, ok := counts[question.Difficulty]; !ok {
			return nil, &content.Error{Kind: "difficulty", Path: draft.QuizID + "/" + question.QuestionID}
		}
		counts[question.Difficulty]++
	}
	return counts, nil
}

func catalogPlayablePacks(packs []auditPack, aliases map[string]string) ([]auditPack, error) {
	known := make(map[string]bool, len(packs))
	for _, pack := range packs {
		known[pack.CanonicalID] = true
	}
	for source, target := range aliases {
		// A partial fixture or a future source collection can legitimately omit a
		// legacy source. Only aliases that apply to this audited collection affect
		// its public catalog.
		if !known[source] {
			continue
		}
		if source == "" || target == "" || source == target || !known[target] || aliases[target] != "" {
			return nil, &content.Error{Kind: "round_alias", Path: source + "->" + target}
		}
	}
	playable := make([]auditPack, 0, len(packs))
	for _, pack := range packs {
		if aliases[pack.CanonicalID] == "" && pack.Questions >= attempts.MinimumAttemptQuestions {
			playable = append(playable, pack)
		}
	}
	return playable, nil
}

func loadTaxonomy(path string) (*content.Taxonomy, error) {
	if path == "" {
		return nil, nil
	}
	return content.LoadTaxonomy(path)
}
func samePath(a, b string) bool {
	aa, ea := filepath.Abs(a)
	bb, eb := filepath.Abs(b)
	if ea == nil && eb == nil && strings.EqualFold(aa, bb) {
		return true
	}
	ai, ea := os.Stat(a)
	bi, eb := os.Stat(b)
	return ea == nil && eb == nil && os.SameFile(ai, bi)
}
