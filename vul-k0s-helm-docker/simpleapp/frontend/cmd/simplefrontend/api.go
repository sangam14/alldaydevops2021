package main

import (
	"bufio"
	"fmt"
	"net/http"
)

func getMessage() (string, error) {
	backendURL := getEnv("BACKEND_URL", "http://localhost:8080")
	var message string

	resp, err := http.Get(backendURL)
	if err != nil {
		return message, err
	}

	defer resp.Body.Close()

	if resp.StatusCode != 200 {
		return message, fmt.Errorf("Server Not Responding %d", resp.StatusCode)
	}

	scanner := bufio.NewScanner(resp.Body)

	if err := scanner.Err(); err != nil {
		return message, err
	}

	if !scanner.Scan() {
		return message, fmt.Errorf("Empty Result")
	}

	message = fmt.Sprintln(scanner.Text())
	return message, nil
}
