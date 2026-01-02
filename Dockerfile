# Build stage
FROM golang:1.24-alpine AS builder

WORKDIR /app

# Install build dependencies (gcc and musl-dev needed for CGO if required)
RUN apk add --no-cache git gcc musl-dev

# Copy go mod files
COPY go.mod go.sum ./
RUN go mod download

# Copy source code
COPY . .

# Build the application
RUN CGO_ENABLED=1 GOOS=linux go build -a -installsuffix cgo -o quiz-server ./cmd/api/main.go

# Runtime stage
FROM alpine:latest

WORKDIR /app

# Install runtime dependencies (for SQLite and healthcheck)
RUN apk add --no-cache ca-certificates sqlite wget

# Copy binary from builder
COPY --from=builder /app/quiz-server .

# Copy quizzes directory
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

