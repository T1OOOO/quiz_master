package observability

import (
	"database/sql"
	"net/http"
	"strconv"
	"time"

	"github.com/prometheus/client_golang/prometheus"
	"github.com/prometheus/client_golang/prometheus/promauto"
	"github.com/prometheus/client_golang/prometheus/promhttp"
)

var (
	httpRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "quiz_master_http_requests_total",
			Help: "Total HTTP requests served by quiz_master services.",
		},
		[]string{"service", "method", "route", "status"},
	)

	httpRequestDurationSeconds = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "quiz_master_http_request_duration_seconds",
			Help:    "HTTP request duration in seconds.",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"service", "method", "route", "status"},
	)

	serviceInfo = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "quiz_master_service_info",
			Help: "Static service info gauge set to 1 for each running service.",
		},
		[]string{"service"},
	)

	dbTableRows = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "quiz_master_db_table_rows",
			Help: "Current row counts by database table.",
		},
		[]string{"service", "table"},
	)

	dbPingStatus = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "quiz_master_db_ping_ok",
			Help: "Database ping status by service. 1 means healthy.",
		},
		[]string{"service"},
	)

	dbOpenConnections = promauto.NewGaugeVec(
		prometheus.GaugeOpts{
			Name: "quiz_master_db_open_connections",
			Help: "Open database connections by service.",
		},
		[]string{"service"},
	)

	upstreamRequestsTotal = promauto.NewCounterVec(
		prometheus.CounterOpts{
			Name: "quiz_master_upstream_requests_total",
			Help: "Total upstream requests made by internal services.",
		},
		[]string{"service", "upstream", "method", "path", "status_class", "result"},
	)

	upstreamRequestDurationSeconds = promauto.NewHistogramVec(
		prometheus.HistogramOpts{
			Name:    "quiz_master_upstream_request_duration_seconds",
			Help:    "Upstream request duration in seconds.",
			Buckets: prometheus.DefBuckets,
		},
		[]string{"service", "upstream", "method", "path", "status_class", "result"},
	)
)

func RecordHTTPRequest(service, method, route string, statusCode int, duration time.Duration) {
	status := strconv.Itoa(statusCode)
	httpRequestsTotal.WithLabelValues(service, method, route, status).Inc()
	httpRequestDurationSeconds.WithLabelValues(service, method, route, status).Observe(duration.Seconds())
}

func MarkService(service string) {
	serviceInfo.WithLabelValues(service).Set(1)
}

func RecordUpstreamRequest(service, upstream, method, path string, statusCode int, duration time.Duration, err error) {
	statusClass := "none"
	result := "success"
	if statusCode > 0 {
		statusClass = strconv.Itoa(statusCode/100) + "xx"
	}
	if err != nil {
		result = "error"
	}
	upstreamRequestsTotal.WithLabelValues(service, upstream, method, path, statusClass, result).Inc()
	upstreamRequestDurationSeconds.WithLabelValues(service, upstream, method, path, statusClass, result).Observe(duration.Seconds())
}

func MetricsHandler(service string, db *sql.DB) http.Handler {
	MarkService(service)
	base := promhttp.Handler()
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		refreshDBMetrics(service, db)
		base.ServeHTTP(w, r)
	})
}

func refreshDBMetrics(service string, db *sql.DB) {
	if db == nil {
		return
	}

	if err := db.Ping(); err != nil {
		dbPingStatus.WithLabelValues(service).Set(0)
		return
	}
	dbPingStatus.WithLabelValues(service).Set(1)

	stats := db.Stats()
	dbOpenConnections.WithLabelValues(service).Set(float64(stats.OpenConnections))

	for _, table := range []string{"users", "quizzes", "questions", "quiz_results", "reports", "refresh_tokens"} {
		var count int64
		if err := db.QueryRow("SELECT COUNT(*) FROM " + table).Scan(&count); err != nil {
			continue
		}
		dbTableRows.WithLabelValues(service, table).Set(float64(count))
	}
}
