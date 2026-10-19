package content

// PlayableQuizID resolves a legacy ID once for new catalog and attempt paths.
// Stored attempt bundles retain their original immutable IDs and never call it.
func PlayableQuizID(id string) string {
	return playableQuizID(id, RoundAliases)
}

func playableQuizID(id string, aliases map[string]string) string {
	if target := aliases[id]; target != "" {
		return target
	}
	return id
}
