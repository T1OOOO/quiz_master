# syntax=docker/dockerfile:1@sha256:ecfaec9ed6d810b56388c508f4121597bfbba70d41a6dfeee4d8cad5f295fc32
FROM golang:1.25.0-bookworm@sha256:81dc45d05a7444ead8c92a389621fafabc8e40f8fd1a19d7e5df14e61e98bc1a AS build

WORKDIR /src
COPY go.mod go.sum ./
RUN go mod download
COPY next/server ./next/server
RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags='-s -w' -o /out/quiz-v2-api ./next/server/cmd/api \
    && printf '%s\n' 'package main' 'import ("net/http"; "os")' 'func main() { r, e := http.Get(os.Args[1]); if e != nil || r.StatusCode != http.StatusOK { os.Exit(1) } }' >/tmp/healthprobe.go \
    && CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -trimpath -ldflags='-s -w' -o /out/healthprobe /tmp/healthprobe.go

FROM gcr.io/distroless/static-debian12:nonroot@sha256:afa5c872c891853ca7fcf1f12c3edb23f7eeef36189728842dd51042ff57f7ab
COPY --from=build /out/quiz-v2-api /quiz-v2-api
COPY --from=build /out/healthprobe /healthprobe
USER nonroot:nonroot
EXPOSE 8080
ENTRYPOINT ["/quiz-v2-api"]
