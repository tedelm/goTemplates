package repository

import (
	"errors"
	"sync"

	"github.com/tedelm/gotemplates/goapisimple/goapisimple/src/internal/models"
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
