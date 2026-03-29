package main

import (
	"quiz_master/internal/authserver"
	"quiz_master/internal/config"
)

func main() {
	cfg := config.Load()
	if err := authserver.Run(cfg); err != nil {
		panic(err)
	}
}
