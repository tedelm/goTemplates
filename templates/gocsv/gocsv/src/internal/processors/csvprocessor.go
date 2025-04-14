package processors

import (
	"strconv"

	"github.com/tedelm/gotemplates/gocsv/gocsv/src/internal/models"
)

// ProcessCSV processes CSV data and returns structured records
func ProcessCSV(data [][]string) []*models.Record {
	var records []*models.Record
	
	// Skip header row
	for i := 1; i < len(data); i++ {
		row := data[i]
		if len(row) >= 5 {
			// Convert string value to float
			value, err := strconv.ParseFloat(row[2], 64)
			if err != nil {
				value = 0.0
			}
			
			// Create a new record
			record := models.NewRecord(
				row[0],
				row[1],
				value,
				row[3],
				row[4],
			)
			
			records = append(records, record)
		}
	}
	
	return records
}
