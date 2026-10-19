// minimum20-bindings rebuilds the reviewed derived banks with public source
// locations and captures their public reader snapshots. It deliberately uses
// the finite evidence produced by the accepted pool materializer.
package main

import (
	"encoding/json"
	"flag"
	"fmt"
	"os"
	"path/filepath"

	"quiz_master/next/server/internal/content"
)

const (
	expectedTargets = 23
	version         = "source-v1"
	publishedAt     = "2026-10-02T00:00:00Z"
)

type materializationEvidence struct {
	PlanSHA256 string `json:"plan_sha256"`
	Targets    []struct {
		QuizID string `json:"quiz_id"`
		Raw    string `json:"raw"`
	} `json:"targets"`
}

func fail(err error) {
	if err != nil {
		panic(err)
	}
}

func main() {
	repo := flag.String("repo", ".", "repository root")
	evidencePath := flag.String("evidence", "docs/rewrite-agents/tasks/FEEDBACK43_MINIMUM20_20261019/pool-materialization-evidence.json", "accepted pool materialization evidence")
	apply := flag.Bool("apply", false, "write canonical artifacts and public snapshots")
	flag.Parse()

	repoRoot, err := filepath.Abs(*repo)
	fail(err)
	evidenceFile := *evidencePath
	if !filepath.IsAbs(evidenceFile) {
		evidenceFile = filepath.Join(repoRoot, evidenceFile)
	}
	data, err := os.ReadFile(evidenceFile)
	fail(err)
	var evidence materializationEvidence
	fail(json.Unmarshal(data, &evidence))
	if evidence.PlanSHA256 != "a9fc8a92e7902b23d9b269e5eaa4cdaf2edfc95c37dc413aadb0543b09ec5f29" || len(evidence.Targets) != expectedTargets {
		panic("minimum20 accepted materialization evidence is incomplete or unexpected")
	}
	seen := map[string]bool{}
	for _, target := range evidence.Targets {
		if target.QuizID == "" || target.Raw == "" || seen[target.QuizID] || !isQuizPath(target.Raw) {
			panic("minimum20 evidence has an invalid target")
		}
		seen[target.QuizID] = true
	}
	if !*apply {
		fmt.Printf("ready: %d reviewed minimum20 targets\n", len(evidence.Targets))
		return
	}

	taxonomy, err := content.LoadTaxonomy(filepath.Join(repoRoot, "metadata", "tags.v1.json"))
	fail(err)
	schemas := filepath.Join(repoRoot, content.DefaultSchemas)
	for _, target := range evidence.Targets {
		rebuild(repoRoot, taxonomy, schemas, target.QuizID, filepath.FromSlash(target.Raw))
	}
	fmt.Printf("generated: %d canonical artifacts and public snapshots\n", len(evidence.Targets))
}

func isQuizPath(raw string) bool {
	clean := filepath.ToSlash(filepath.Clean(raw))
	return clean != "." && clean == raw && len(clean) > len("quizzes/") && clean[:len("quizzes/")] == "quizzes/"
}

func rebuild(repoRoot string, taxonomy *content.Taxonomy, schemas, quizID, raw string) {
	rawPath := filepath.Join(repoRoot, raw)
	draft, manifest, err := content.ImportWithTaxonomy(rawPath, taxonomy)
	fail(err)
	publicSource := "/app/" + filepath.ToSlash(raw)
	for i := range draft.Questions {
		if draft.Questions[i].Source == nil {
			draft.Questions[i].Source = map[string]string{}
		}
		draft.Questions[i].Source["uri"] = publicSource
	}
	manifest.SourcePath = publicSource
	content.Rehash(&draft)
	fail(content.ValidateDraftWithTaxonomy(draft, schemas, taxonomy))
	bundle, err := content.BuildWithTaxonomy(draft, version, publishedAt, taxonomy, schemas)
	fail(err)

	out := filepath.Join(repoRoot, "next", "content", quizID)
	writeJSON(filepath.Join(out, "draft.json"), draft)
	writeJSON(filepath.Join(out, "manifest.json"), manifest)
	writeJSON(filepath.Join(out, "bundle.json"), bundle)
	public, err := json.MarshalIndent(map[string]any{"quiz": bundle.Quiz}, "", "  ")
	fail(err)
	public = append(public, '\n')
	snapshot := filepath.Join(repoRoot, "study", "question_articles", "snapshots", quizID+".json")
	fail(writeAtomic(snapshot, public))
}

func writeJSON(path string, value any) {
	data, err := json.MarshalIndent(value, "", "  ")
	fail(err)
	fail(writeAtomic(path, append(data, '\n')))
}

func writeAtomic(path string, data []byte) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil {
		return err
	}
	temporary, err := os.CreateTemp(filepath.Dir(path), ".minimum20-*")
	if err != nil {
		return err
	}
	name := temporary.Name()
	defer os.Remove(name)
	if _, err = temporary.Write(data); err == nil {
		err = temporary.Close()
	}
	if err != nil {
		return err
	}
	return os.Rename(name, path)
}
