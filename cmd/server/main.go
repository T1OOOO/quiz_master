package main

import (
	"quiz_master/internal/config"
	"quiz_master/internal/server"
)

func main() {
	cfg := config.Load()
	if err := server.Run(cfg); err != nil {
		panic(err)
	}
}
