# Build stage
FROM golang:alpine AS builder

WORKDIR /app

# Install git (needed for fetching dependencies sometimes)
RUN apk add --no-cache git

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
# modernc.org/sqlite is pure Go, so CGO_ENABLED=0 is preferred
RUN CGO_ENABLED=0 GOOS=linux go build -ldflags="-w -s" -o quiz-server ./cmd/api/main.go

# Runtime stage
FROM alpine:latest

WORKDIR /app

# Install ca-certificates for HTTPS and Timezone data
RUN apk add --no-cache ca-certificates tzdata

# Copy binary from builder
COPY --from=builder /app/quiz-server .

# Copy quizzes directory
# App scans this dir on startup/sync
COPY quizzes ./quizzes

# Create directory for database
RUN mkdir -p /app/data

# Expose port
EXPOSE 8085

# Set environment variables
ENV PORT=8085
ENV DB_PATH=/app/data/quiz.db
ENV ENV=production

# Run the application
CMD ["./quiz-server"]

