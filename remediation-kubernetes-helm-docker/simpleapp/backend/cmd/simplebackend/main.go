package main

import (
	"fmt"
	"net/http"
	"time"
)

func main() {
	port := 8080

	http.HandleFunc("/", handlerPing)

	var address = fmt.Sprintf(":%d", port)
	fmt.Printf("simple backend server started at %d\n", port)
	err := http.ListenAndServe(address, nil)
	if err != nil {
		panic(err)
	}
}

func logPrint(message string, status bool) {
	now := time.Now().String()
	var slog string
	if status {
		slog = "OK"
	} else {
		slog = "ERROR"
	}
	log := fmt.Sprintf("[%s] %s => %s", slog, now, message)
	fmt.Println(log)
}

func handlerPing(w http.ResponseWriter, r *http.Request) {
	message := "Hello from simpleapp"
	w.WriteHeader(http.StatusOK)
	w.Write([]byte(message))
	logPrint(message,true)
}

