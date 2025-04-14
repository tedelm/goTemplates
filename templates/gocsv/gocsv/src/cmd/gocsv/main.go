package main

import (
	"fmt"
	"os"
	"encoding/csv"
	"log"
    "github.com/joho/godotenv"

    "github.com/tedelm/gotemplates/gocsv/gocsv/src/internal/processors"
)

func main() {
	fmt.Println("Starting gocsv CSV processor!")

    // Load environment variables
    err := godotenv.Load("../../env/.env")
    if err != nil {
        log.Fatalf("Error loading .env file: %v", err)
    }

    fmt.Println("CSV_FILE_PATH: ", os.Getenv("CSV_FILE_PATH"))
	
	// Open the CSV file
	file, err := os.Open(os.Getenv("CSV_FILE_PATH"))
	if err != nil {
		log.Fatalf("Failed to open CSV file: %v", err)
	}
	defer file.Close()
	
	// Create a new CSV reader
	reader := csv.NewReader(file)
	
	// Read all records
	records, err := reader.ReadAll()
	if err != nil {
		log.Fatalf("Failed to read CSV: %v", err)
	}
	
	// Process the records
	processedData := processors.ProcessCSV(records)

    // Print the processed data
    fmt.Println("Processed data:")
    for _, record := range processedData {
        fmt.Printf("ID: %s, Name: %s, Value: %f, Category: %s, Timestamp: %s\n", record.ID, record.Name, record.Value, record.Category, record.Timestamp)
    }
	
	fmt.Printf("Processed %d records successfully!\n", len(processedData))
}
