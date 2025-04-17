package handlers

import (
	"encoding/json"
	"net/http"
	"crypto/rand"
	"fmt"
	"io"
	"time"

	"github.com/tedelm/gotemplates/goapisimple/goapisimple/src/internal/models"
	"github.com/tedelm/gotemplates/goapisimple/goapisimple/src/internal/repository"
)

// UserHandler handles HTTP requests for users
type UserHandler struct {
	userRepo *repository.UserRepository
}

// NewUserHandler creates a new user handler
func NewUserHandler(userRepo *repository.UserRepository) *UserHandler {
	return &UserHandler{
		userRepo: userRepo,
	}
}

// generateID creates a simple random ID
func generateID() string {
	b := make([]byte, 16)
	_, err := rand.Read(b)
	if err != nil {
		return fmt.Sprintf("%d", time.Now().UnixNano())
	}
	return fmt.Sprintf("%x", b)
}

// GetUsers returns all users
func (h *UserHandler) GetUsers(w http.ResponseWriter, r *http.Request) {
	users := h.userRepo.GetAll()
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(users)
}

// GetUser returns a specific user by ID
func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request, id string) {
	user, err := h.userRepo.GetByID(id)
	if err != nil {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

// CreateUser creates a new user
func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
	var user models.User
	
	// Read request body
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Error reading request body", http.StatusBadRequest)
		return
	}
	
	// Parse JSON
	err = json.Unmarshal(body, &user)
	if err != nil {
		http.Error(w, "Invalid JSON format", http.StatusBadRequest)
		return
	}
	
	// Generate a new ID if not provided
	if user.ID == "" {
		user.ID = generateID()
	}
	
	// Set timestamps
	now := time.Now()
	user.CreatedAt = now
	user.UpdatedAt = now
	
	err = h.userRepo.Create(&user)
	if err != nil {
		http.Error(w, err.Error(), http.StatusConflict)
		return
	}
	
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusCreated)
	json.NewEncoder(w).Encode(user)
}

// UpdateUser updates an existing user
func (h *UserHandler) UpdateUser(w http.ResponseWriter, r *http.Request, id string) {
	// Check if user exists
	_, err := h.userRepo.GetByID(id)
	if err != nil {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}
	
	var user models.User
	
	// Read request body
	body, err := io.ReadAll(r.Body)
	if err != nil {
		http.Error(w, "Error reading request body", http.StatusBadRequest)
		return
	}
	
	// Parse JSON
	err = json.Unmarshal(body, &user)
	if err != nil {
		http.Error(w, "Invalid JSON format", http.StatusBadRequest)
		return
	}
	
	// Ensure ID matches the URL parameter
	user.ID = id
	
	// Update timestamp
	user.UpdatedAt = time.Now()
	
	err = h.userRepo.Update(&user)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}
	
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(user)
}

// DeleteUser deletes a user
func (h *UserHandler) DeleteUser(w http.ResponseWriter, r *http.Request, id string) {
	err := h.userRepo.Delete(id)
	if err != nil {
		http.Error(w, "User not found", http.StatusNotFound)
		return
	}
	
	w.WriteHeader(http.StatusNoContent)
}
