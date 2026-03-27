package main

import (
	"context"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"time"

	"quiz_master/internal/config"
	quizservice "quiz_master/internal/quiz/service"
	storagedb "quiz_master/internal/storage/db"
	storagerepo "quiz_master/internal/storage/repository"
)

func main() {
	var (
		action  = flag.String("action", "init", "database action: init|reset|path|import-quizzes")
		dbPath  = flag.String("db", "", "override DB path")
		quizzes = flag.String("quizzes", "", "override quizzes directory for import-quizzes")
		prune   = flag.Bool("prune", false, "delete quizzes from DB that are missing on disk during import-quizzes")
	)
	flag.Parse()

	cfg := config.Load()
	path := cfg.DBPath
	if *dbPath != "" {
		path = *dbPath
	}

	switch *action {
	case "path":
		fmt.Println(path)
		return
	case "reset":
		if err := resetDB(path); err != nil {
			fail(err)
		}
		if err := initDB(path); err != nil {
			fail(err)
		}
	case "init":
		if err := initDB(path); err != nil {
			fail(err)
		}
	case "import-quizzes":
		dir := cfg.QuizzesDir
		if *quizzes != "" {
			dir = *quizzes
		}
		if err := importQuizzes(path, dir, *prune); err != nil {
			fail(err)
		}
	default:
		fail(fmt.Errorf("unsupported action %q", *action))
	}

	fmt.Printf("database %s complete: %s\n", *action, path)
}

func initDB(path string) error {
	if err := os.MkdirAll(filepath.Dir(path), 0o755); err != nil && filepath.Dir(path) != "." {
		return err
	}

	db, err := storagedb.Open(context.Background(), storagedb.Config{
		Path:         path,
		MaxOpenConns: 1,
		MaxIdleConns: 1,
		ConnMaxIdle:  time.Minute,
	})
	if err != nil {
		return err
	}
	return db.Close()
}

func resetDB(path string) error {
	for _, candidate := range []string{path, path + "-shm", path + "-wal"} {
		if err := os.Remove(candidate); err != nil && !os.IsNotExist(err) {
			return err
		}
	}
	return nil
}

func importQuizzes(dbPath, quizzesDir string, prune bool) error {
	db, err := storagedb.Open(context.Background(), storagedb.Config{
		Path:         dbPath,
		MaxOpenConns: 1,
		MaxIdleConns: 1,
		ConnMaxIdle:  time.Minute,
	})
	if err != nil {
		return err
	}
	defer db.Close()

	repo := storagerepo.NewQuizRepository(db)
	svc := quizservice.New(repo)
	return svc.SyncFromFiles(quizzesDir, quizservice.SyncOptions{PruneMissing: prune})
}

func fail(err error) {
	fmt.Fprintln(os.Stderr, err)
	os.Exit(1)
}
