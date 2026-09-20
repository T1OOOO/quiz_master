package config

import (
	"path/filepath"
	"testing"
	"time"
)

func TestAttemptConfiguration(t *testing.T) {
	t.Setenv("QM_LISTEN_ADDR", "127.0.0.1:8088")
	t.Setenv("QM_DATABASE_URL", "postgres://local/test")
	t.Setenv("QM_CONTENT_BUNDLE_PATH", "")
	t.Setenv("QM_CONTENT_MANIFEST_PATH", "")
	t.Setenv("QM_ATTEMPT_DURATION", "")
	c, err := FromEnv()
	if err != nil {
		t.Fatal(err)
	}
	if c.AttemptDuration != 30*time.Minute || c.ContentBundlePath != "next/content/home-alone-1-part-1/bundle.json" || c.ContentManifestPath != filepath.FromSlash("next/content/home-alone-1-part-1/manifest.json") {
		t.Fatal("invalid local defaults")
	}
	t.Setenv("QM_CONTENT_BUNDLE_PATH", "controlled/bundle.json")
	t.Setenv("QM_CONTENT_MANIFEST_PATH", "controlled/manifest.json")
	for _, raw := range []string{"5m", "24h", "30m"} {
		t.Setenv("QM_ATTEMPT_DURATION", raw)
		c, err = FromEnv()
		if err != nil || c.ContentBundlePath != "controlled/bundle.json" || c.ContentManifestPath != "controlled/manifest.json" {
			t.Fatal(raw, err)
		}
	}
	for _, raw := range []string{"0s", "-1m", "299s", "24h1s", "bad"} {
		t.Setenv("QM_ATTEMPT_DURATION", raw)
		if _, err = FromEnv(); err == nil {
			t.Fatal("accepted duration", raw)
		}
	}
}

func TestNonlocalListenRequiresExplicitControlledBundle(t *testing.T) {
	t.Setenv("QM_LISTEN_ADDR", "0.0.0.0:8088")
	t.Setenv("QM_DATABASE_URL", "postgres://local/test")
	t.Setenv("QM_CONTENT_BUNDLE_PATH", "")
	t.Setenv("QM_CONTENT_MANIFEST_PATH", "")
	if _, err := FromEnv(); err == nil {
		t.Fatal("nonlocal server silently selected development content")
	}
	t.Setenv("QM_CONTENT_BUNDLE_PATH", "controlled/bundle.json")
	if _, err := FromEnv(); err == nil {
		t.Fatal("nonlocal server silently selected a manifest")
	}
	t.Setenv("QM_CONTENT_MANIFEST_PATH", "controlled/manifest.json")
	if _, err := FromEnv(); err != nil {
		t.Fatal(err)
	}
}

func TestLoopbackManifestDefaultsBesideExplicitBundle(t *testing.T) {
	t.Setenv("QM_LISTEN_ADDR", "localhost:8088")
	t.Setenv("QM_DATABASE_URL", "postgres://local/test")
	t.Setenv("QM_CONTENT_BUNDLE_PATH", "controlled/pack/bundle.json")
	t.Setenv("QM_CONTENT_MANIFEST_PATH", "")
	c, err := FromEnv()
	if err != nil {
		t.Fatal(err)
	}
	if c.ContentManifestPath != filepath.FromSlash("controlled/pack/manifest.json") {
		t.Fatalf("manifest path = %q", c.ContentManifestPath)
	}
}
