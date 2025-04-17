#Create project structure

param (
    [Parameter(Mandatory = $true)][string]$projectName,
    [Parameter(Mandatory = $false)][string]$mainProjectPath = "D:\GO",
    [Parameter(Mandatory = $false)][string]$projectGithubRepo = "github.com/username"
)

$githubProjectSrcPath = $projectGithubRepo + "/" + $projectName + "/src"

try {
    $projectPath = "$mainProjectPath\$projectName"
    #Create project folder
    New-Item -Path $projectPath -ItemType Directory

    Set-Location $projectPath

    #Create project files
    New-Item -Path $projectPath\src -ItemType Directory
    New-Item -Path $projectPath\src\cmd -ItemType Directory
    New-Item -Path $projectPath\src\cmd\$projectName -ItemType Directory
    New-Item -Path $projectPath\src\cmd\$projectName\main.go -ItemType File

    #Create project internal folder
    New-Item -Path $projectPath\src\internal\ -ItemType Directory

    #Create project internal handlers folder - for API handlers
    New-Item -Path $projectPath\src\internal\handlers\ -ItemType Directory
    New-Item -Path $projectPath\src\internal\handlers\userhandler.go -ItemType File

    #Create project internal models folder - for data models
    New-Item -Path $projectPath\src\internal\models\ -ItemType Directory
    New-Item -Path $projectPath\src\internal\models\user.go -ItemType File

    #Create project internal repository folder - for data storage
    New-Item -Path $projectPath\src\internal\repository\ -ItemType Directory
    New-Item -Path $projectPath\src\internal\repository\userrepository.go -ItemType File

    #Create project docs folder - example: stores documentation
    New-Item -Path $projectPath\src\docs -ItemType Directory
    New-Item -Path $projectPath\src\docs\documentation.md -ItemType File

    #Create .env file
    New-Item -Path $projectPath\src\env -ItemType Directory
    New-Item -Path $projectPath\src\env\.env.example -ItemType File
    New-Item -Path $projectPath\src\env\.env -ItemType File

} catch {
    Write-Error "Error creating project structure: $_"
    Write-Host "Rolling back changes..."
    Remove-Item -Path $projectPath -Recurse
    Read-Host "Press Enter to exit..."
    exit 1
}


# Initialize Go module
try {
    Set-Location $projectPath
    Write-Host "Initializing Go module..."
    
    # Initialize go.mod file with the project name
    $goModCommand = "go mod init $($projectGithubRepo + "/" + $projectName)"
    Invoke-Expression $goModCommand
    
    # Create a basic main.go file with API setup using standard library
    $mainGoContent = @"
package main

import (
	"fmt"
	"log"
	"net/http"
	"os"
	"github.com/joho/godotenv"

	"$githubProjectSrcPath/internal/handlers"
	"$githubProjectSrcPath/internal/repository"
)

func main() {
	fmt.Println("Starting $projectName API server!")

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
	log.Fatal(http.ListenAndServe(":" + port, nil))
}
"@
    
    Set-Content -Path "$projectPath\src\cmd\$projectName\main.go" -Value $mainGoContent

    # Create a user model file
    $userModelContent = @"
package models

import (
	"time"
)

// User represents a user in the system
type User struct {
	ID        string    `json:"id"`
	Username  string    `json:"username"`
	Email     string    `json:"email"`
	FirstName string    `json:"firstName"`
	LastName  string    `json:"lastName"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// NewUser creates a new user instance
func NewUser(id, username, email, firstName, lastName string) *User {
	now := time.Now()
	return &User{
		ID:        id,
		Username:  username,
		Email:     email,
		FirstName: firstName,
		LastName:  lastName,
		CreatedAt: now,
		UpdatedAt: now,
	}
}
"@
    
    Set-Content -Path "$projectPath\src\internal\models\user.go" -Value $userModelContent

    # Create a user repository file
    $userRepositoryContent = @"
package repository

import (
	"errors"
	"sync"

	"$githubProjectSrcPath/internal/models"
)

// UserRepository handles user data storage
type UserRepository struct {
	users map[string]*models.User
	mutex sync.RWMutex
}

// NewUserRepository creates a new user repository
func NewUserRepository() *UserRepository {
	return &UserRepository{
		users: make(map[string]*models.User),
	}
}

// GetAll returns all users
func (r *UserRepository) GetAll() []*models.User {
	r.mutex.RLock()
	defer r.mutex.RUnlock()
	
	users := make([]*models.User, 0, len(r.users))
	for _, user := range r.users {
		users = append(users, user)
	}
	
	return users
}

// GetByID returns a user by ID
func (r *UserRepository) GetByID(id string) (*models.User, error) {
	r.mutex.RLock()
	defer r.mutex.RUnlock()
	
	user, exists := r.users[id]
	if !exists {
		return nil, errors.New("user not found")
	}
	
	return user, nil
}

// Create adds a new user
func (r *UserRepository) Create(user *models.User) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()
	
	if _, exists := r.users[user.ID]; exists {
		return errors.New("user already exists")
	}
	
	r.users[user.ID] = user
	return nil
}

// Update updates an existing user
func (r *UserRepository) Update(user *models.User) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()
	
	if _, exists := r.users[user.ID]; !exists {
		return errors.New("user not found")
	}
	
	r.users[user.ID] = user
	return nil
}

// Delete removes a user
func (r *UserRepository) Delete(id string) error {
	r.mutex.Lock()
	defer r.mutex.Unlock()
	
	if _, exists := r.users[id]; !exists {
		return errors.New("user not found")
	}
	
	delete(r.users, id)
	return nil
}
"@
    
    Set-Content -Path "$projectPath\src\internal\repository\userrepository.go" -Value $userRepositoryContent

    # Create a user handler file using standard library
    $userHandlerContent = @"
package handlers

import (
	"encoding/json"
	"net/http"
	"crypto/rand"
	"fmt"
	"io"
	"time"

	"$githubProjectSrcPath/internal/models"
	"$githubProjectSrcPath/internal/repository"
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
"@
    
    Set-Content -Path "$projectPath\src\internal\handlers\userhandler.go" -Value $userHandlerContent

    # Add sample content to .env.example
    $envExampleContent = @"
# Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=mydatabase
DB_USER=myuser
DB_PASSWORD=mypassword

# API Configuration
API_PORT=8080
API_SECRET=your_secret_key

# Other Configuration
LOG_LEVEL=debug
ENVIRONMENT=development

# Project Configuration
PROJECT_NAME=$projectName
PROJECT_VERSION=0.1.0
PROJECT_DESCRIPTION="A simple REST API for user management using standard library"
"@

    Set-Content -Path "$projectPath\src\env\.env.example" -Value $envExampleContent 
    Set-Content -Path "$projectPath\src\env\.env" -Value $envExampleContent

    $gitignoreContent = @"
# Environment variables
.env

# Go binaries
*.exe
*.exe~
*.dll
*.so
*.dylib

# Go specific
*.test
*.out
go.work

# IDE specific
.idea/
.vscode/
*.swp
*.swo
"@
    
    Set-Content -Path "$projectPath\.gitignore" -Value $gitignoreContent    

    # Run go mod tidy to clean up dependencies
    Invoke-Expression "go get github.com/joho/godotenv"
    Invoke-Expression "go mod tidy"
    
    Write-Host "Go API module initialized successfully!"
} catch {
    Write-Error "Error initializing Go module: $_"
    Read-Host "Press Enter to continue..."
}
