package models

// Record represents a data record from CSV
type Record struct {
	ID        string
	Name      string
	Value     float64
	Category  string
	Timestamp string
}

// NewRecord creates a new record instance
func NewRecord(id, name string, value float64, category, timestamp string) *Record {
	return &Record{
		ID:        id,
		Name:      name,
		Value:     value,
		Category:  category,
		Timestamp: timestamp,
	}
}
