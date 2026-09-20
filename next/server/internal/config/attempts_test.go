package config

import (
	"testing"
	"time"
)

func TestAttemptConfiguration(t *testing.T) {
	t.Setenv("QM_LISTEN_ADDR", "127.0.0.1:8088")
	t.Setenv("QM_DATABASE_URL", "postgres://local/test")
	t.Setenv("QM_CONTENT_BUNDLE_PATH", "")
	t.Setenv("QM_ATTEMPT_DURATION", "")
	c, err := FromEnv()
	if err != nil {
		t.Fatal(err)
	}
	if c.AttemptDuration != 30*time.Minute || c.ContentBundlePath != "next/content/home-alone-1-part-1/bundle.json" {
		t.Fatal("invalid local defaults")
	}
	t.Setenv("QM_CONTENT_BUNDLE_PATH", "controlled/bundle.json")
	for _, raw := range []string{"5m", "24h", "30m"} {
		t.Setenv("QM_ATTEMPT_DURATION", raw)
		c, err = FromEnv()
		if err != nil || c.ContentBundlePath != "controlled/bundle.json" {
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
	if _, err := FromEnv(); err == nil {
		t.Fatal("nonlocal server silently selected development content")
	}
	t.Setenv("QM_CONTENT_BUNDLE_PATH", "controlled/bundle.json")
	if _, err := FromEnv(); err != nil {
		t.Fatal(err)
	}
}
