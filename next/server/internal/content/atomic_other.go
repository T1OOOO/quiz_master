//go:build !windows

package content

import "os"

func publishFile(from, to string, force bool) error {
	if force {
		return os.Rename(from, to)
	}
	// Link is an atomic no-replace publication on the same filesystem; unlike
	// portable Rename it cannot overwrite a destination created by another process.
	if e := os.Link(from, to); e != nil {
		return e
	}
	_ = os.Remove(from)
	return nil
}
