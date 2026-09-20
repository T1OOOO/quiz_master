package content

import "golang.org/x/sys/windows"

func publishFile(from, to string, force bool) error {
	src, e := windows.UTF16PtrFromString(from)
	if e != nil {
		return e
	}
	dst, e := windows.UTF16PtrFromString(to)
	if e != nil {
		return e
	}
	var flags uint32
	if force {
		flags = windows.MOVEFILE_REPLACE_EXISTING
	}
	return windows.MoveFileEx(src, dst, flags)
}
