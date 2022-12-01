package main

import (
	"log"
	"net/http"
)

func main() {
	// create the fileserver handler
	fs := http.FileServer(http.Dir("/var/www/html"))

	// start HTTP server with fileserver as the handler
	log.Fatal(http.ListenAndServe(":8080", fs))
}
