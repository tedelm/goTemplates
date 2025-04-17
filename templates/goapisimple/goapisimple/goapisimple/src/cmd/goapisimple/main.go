package main

import (
	"fmt"
	"log"
	"net/http"
	"os"

	"github.com/joho/godotenv"

	"github.com/tedelm/gotemplates/goapisimple/goapisimple/src/internal/handlers"
	"github.com/tedelm/gotemplates/goapisimple/goapisimple/src/internal/repository"
)

func main() {
	fmt.Println("Starting goapisimple API server!")

	// Load environment variables
	err := godotenv.Load("../../env/.env")
	if err != nil {
		log.Fatalf("Error loading .env file: %v", err)
	}

	// Initialize user repository
	userRepo := repository.NewUserRepository()

	// Initialize handlers
	userHandler := handlers.NewUserHandler(userRepo)

	// Register routes using standard http package
	http.HandleFunc("/api/users", func(w http.ResponseWriter, r *http.Request) {
		switch r.Method {
		case http.MethodGet:
			userHandler.GetUsers(w, r)
		case http.MethodPost:
			userHandler.CreateUser(w, r)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})

	http.HandleFunc("/api/users/", func(w http.ResponseWriter, r *http.Request) {
		// Extract ID from URL path
		id := r.URL.Path[len("/api/users/"):]
		if id == "" {
			http.Error(w, "Invalid user ID", http.StatusBadRequest)
			return
		}

		fmt.Println("Fetching user with ID:", id)

		switch r.Method {
		case http.MethodGet:
			userHandler.GetUser(w, r, id)
		case http.MethodPut:
			userHandler.UpdateUser(w, r, id)
		case http.MethodDelete:
			userHandler.DeleteUser(w, r, id)
		default:
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
		}
	})

	// Start server
	port := os.Getenv("API_PORT")
	if port == "" {
		port = "8080"
	}

	fmt.Printf("Server starting on port %s...\n", port)
	log.Fatal(http.ListenAndServe(":"+port, nil))
}
