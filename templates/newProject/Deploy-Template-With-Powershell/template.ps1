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

    #Create project internal models folder - for data models
    New-Item -Path $projectPath\src\internal\models\ -ItemType Directory
	
    #Create project internal repository folder - for processors
    New-Item -Path $projectPath\src\internal\processors\ -ItemType Directory

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

	"github.com/joho/godotenv"
)

func main() {
	fmt.Println("Starting $projectName API server!")

	// Load environment variables
	err := godotenv.Load("../../env/.env")
	if err != nil {
		log.Fatalf("Error loading .env file: %v", err)
	}

}
"@
    
    Set-Content -Path "$projectPath\src\cmd\$projectName\main.go" -Value $mainGoContent

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
    
    Write-Host "Go initialized successfully!"
} catch {
    Write-Error "Error initializing Go module: $_"
    Read-Host "Press Enter to continue..."
}

$documentationContent = @"
# $projectName Documentation
.\template.ps1 -projectName newproject -mainProjectPath D:\Priv\Github.com\goTemplates\templates\newproject -projectGithubRepo github.com/tedelm/goTemplates/tree/main/templates/newproject
"@

Set-Content -Path "$projectPath\src\docs\documentation.md" -Value $documentationContent
