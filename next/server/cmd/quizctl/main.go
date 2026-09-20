// quizctl operates on local, controlled private content only.
package main

import (
	"flag"
	"fmt"
	"io"
	"os"
	"path/filepath"
	"strings"

	"quiz_master/next/server/internal/content"
)

func main() { os.Exit(run(os.Args[1:], os.Stdout, os.Stderr)) }

// Exit contract: 0 successful/no semantic differences; 1 differences; 2 error.
func run(args []string, out, errOut io.Writer) int {
	fail := func(e error) int { fmt.Fprintln(errOut, "quizctl:", e); return 2 }
	usage := func() int {
		return fail(&content.Error{Kind: "usage", Path: "quizctl import|validate|build|diff (see next/content/README.md)"})
	}
	if len(args) == 0 {
		return usage()
	}
	command := args[0]
	fs := flag.NewFlagSet(command, flag.ContinueOnError)
	fs.SetOutput(io.Discard)
	schemaDir := fs.String("schemas", content.DefaultSchemas, "local accepted schema directory")
	var in, outPath, before, after, version, publishedAt *string
	var force *bool
	switch command {
	case "import", "build":
		in = fs.String("in", "", "input file")
		outPath = fs.String("out", "", "import directory or bundle file")
		force = fs.Bool("force", false, "explicit overwrite")
		if command == "build" {
			version = fs.String("version", "", "explicit bundle version")
			publishedAt = fs.String("published-at", "", "RFC3339 publication timestamp")
		}
	case "validate":
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
	case "import":
		if *in == "" || *outPath == "" {
			return usage()
		}
		for _, name := range []string{"draft.json", "manifest.json"} {
			if samePath(*in, filepath.Join(*outPath, name)) {
				return fail(&content.Error{Kind: "output_path", Path: *outPath})
			}
		}
		d, m, e := content.Import(*in)
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
		for _, p := range paths {
			doc, e := content.ReadDocument(p, *schemaDir)
			if e != nil {
				return fail(e)
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
		b, e := content.Build(doc.Draft, *version, *publishedAt, *schemaDir)
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
