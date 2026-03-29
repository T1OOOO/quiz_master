package main

import (
	"quiz_master/internal/config"
	"quiz_master/internal/storageserver"
)

func main() {
	cfg := config.Load()
	if err := storageserver.Run(cfg); err != nil {
		panic(err)
	}
}
