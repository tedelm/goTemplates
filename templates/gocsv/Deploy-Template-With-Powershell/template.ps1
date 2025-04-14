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

    #Create project internal data processor folder - example: stores functions that process CSV data
    New-Item -Path $projectPath\src\internal\processors\ -ItemType Directory
    New-Item -Path $projectPath\src\internal\processors\csvprocessor.go -ItemType File

    #Create project internal models folder - example: stores data models
    New-Item -Path $projectPath\src\internal\models\ -ItemType Directory
    New-Item -Path $projectPath\src\internal\models\record.go -ItemType File

    #Create project docs folder - example: stores documentation
    New-Item -Path $projectPath\src\docs -ItemType Directory
    New-Item -Path $projectPath\src\docs\documentation.md -ItemType File

    #Create data folder for CSV files
    New-Item -Path $projectPath\data -ItemType Directory
    New-Item -Path $projectPath\data\sample.csv -ItemType File


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
    
    # Create a basic main.go file with CSV processing example
    $mainGoContent = @"
package main

import (
	"fmt"
	"os"
	"encoding/csv"
	"log"
    "github.com/joho/godotenv"

    "$githubProjectSrcPath/internal/processors"
)

func main() {
	fmt.Println("Starting $projectName CSV processor!")

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
"@
    
    Set-Content -Path "$projectPath\src\cmd\$projectName\main.go" -Value $mainGoContent

    # Create a basic record model file
    $recordModelContent = @"
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
"@
    
    Set-Content -Path "$projectPath\src\internal\models\record.go" -Value $recordModelContent

    
    # Create a basic CSV processor file
    $processorContent = @"
package processors

import (
	"strconv"

	"$githubProjectSrcPath/internal/models"
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
"@
    
    Set-Content -Path "$projectPath\src\internal\processors\csvprocessor.go" -Value $processorContent
    
    # Create a sample CSV file
    $sampleCSVContent = @"
ID,Name,Value,Category,Timestamp
1,Item1,10.5,CategoryA,2023-01-01T12:00:00
2,Item2,20.75,CategoryB,2023-01-02T14:30:00
3,Item3,15.25,CategoryA,2023-01-03T09:15:00
"@

    Set-Content -Path "$projectPath\data\sample.csv" -Value $sampleCSVContent

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
PROJECT_DESCRIPTION="A simple project for processing CSV files"

# CSV Configuration
CSV_FILE_PATH=../../../data/sample.csv

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
    Invoke-Expression "go mod tidy"
    
    Write-Host "Go module initialized successfully!"
} catch {
    Write-Error "Error initializing Go module: $_"
    Read-Host "Press Enter to continue..."
}
