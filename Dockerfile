FROM golang:1.24-alpine AS builder

WORKDIR /src

RUN apk add --no-cache git

COPY go.mod go.sum ./
RUN go mod download

COPY cmd ./cmd
COPY internal ./internal
COPY quizzes ./quizzes
COPY web ./web

RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-w -s" -o /out/quiz-server ./cmd/api

FROM alpine:3.22 AS runtime

WORKDIR /app

RUN addgroup -S app && adduser -S -G app app \
    && mkdir -p /app/data /app/quizzes /app/web/dist \
    && chown -R app:app /app

COPY --from=builder /out/quiz-server /app/quiz-server
COPY --chown=app:app quizzes /app/quizzes
COPY --chown=app:app web/dist /app/web/dist

ENV PORT=8085
ENV DB_PATH=/app/data/quiz.db
ENV ENV=production
ENV QUIZZES_DIR=quizzes
ENV JWT_TTL=24h
ENV SHUTDOWN_TIMEOUT=10s

EXPOSE 8085

USER app

CMD ["./quiz-server"]
