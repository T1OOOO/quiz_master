package dbx

import (
	"database/sql"
	"fmt"
	"strings"
	"sync"
)

const (
	DriverSQLite   = "sqlite"
	DriverPostgres = "postgres"
)

var drivers sync.Map

func Register(db *sql.DB, driver string) {
	if db == nil {
		return
	}
	drivers.Store(db, NormalizeDriver(driver))
}

func Driver(db *sql.DB) string {
	if db == nil {
		return DriverSQLite
	}
	if v, ok := drivers.Load(db); ok {
		if driver, ok := v.(string); ok && driver != "" {
			return driver
		}
	}
	return DriverSQLite
}

func NormalizeDriver(driver string) string {
	switch strings.ToLower(strings.TrimSpace(driver)) {
	case "postgres", "postgresql", "pgx":
		return DriverPostgres
	default:
		return DriverSQLite
	}
}

func Rebind(db *sql.DB, query string) string {
	if Driver(db) != DriverPostgres {
		return query
	}

	var b strings.Builder
	index := 1
	for _, ch := range query {
		if ch == '?' {
			b.WriteString(fmt.Sprintf("$%d", index))
			index++
			continue
		}
		b.WriteRune(ch)
	}
	return b.String()
}

func NowExpr(db *sql.DB) string {
	if Driver(db) == DriverPostgres {
		return "CURRENT_TIMESTAMP"
	}
	return "datetime('now')"
}
