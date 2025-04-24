package main

import (
	"database/sql"
	"fmt"
	"log"
	"os"
	"strconv"
	"time"

	env "github.com/joho/godotenv"
	_ "github.com/lib/pq"
)

func main() {

	// Load environment variables
	env.Load(".env")

	// Connection parameters

	host := os.Getenv("DB_HOST")
	port, err := strconv.Atoi(os.Getenv("DB_PORT"))
	if err != nil {
		log.Fatal("Error converting DB_PORT to int: ", err)
	}
	user := os.Getenv("DB_USER")
	password := os.Getenv("DB_PASSWORD")
	dbname := os.Getenv("DB_NAME")

	// Connection string
	psqlInfo := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=disable",
		host, port, user, password, dbname)

	// Open database connection
	db, err := sql.Open("postgres", psqlInfo)
	if err != nil {
		log.Fatal("Error connecting to the database: ", err)
	}
	defer db.Close()

	// Set connection pool parameters
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)
	db.SetConnMaxLifetime(5 * time.Minute)

	// Test the connection
	err = db.Ping()
	if err != nil {
		log.Fatal("Error pinging database: ", err)
	}

	fmt.Println("Successfully connected to database!")

	// Example query
	rows, err := db.Query("SELECT id, name FROM users")
	if err != nil {
		log.Fatal("Error querying database: ", err)
	}
	defer rows.Close()

	// Iterate through results
	for rows.Next() {
		var id int
		var name string
		err = rows.Scan(&id, &name)
		if err != nil {
			log.Fatal("Error scanning row: ", err)
		}
		fmt.Printf("ID: %d, Name: %s\n", id, name)
	}

	// Prepare statement
	stmt, err := db.Prepare("INSERT INTO users(name, email) VALUES($1, $2)")
	if err != nil {
		log.Fatal(err)
	}
	defer stmt.Close()

	// Execute prepared statement
	_, err = stmt.Exec("John Doe", "john@example.com")
	if err != nil {
		log.Fatal(err)
	}

	// Start transaction
	tx, err := db.Begin()
	if err != nil {
		log.Fatal(err)
	}

	// Execute queries
	_, err = tx.Exec("INSERT INTO users(name) VALUES($1)", "Alice")
	if err != nil {
		tx.Rollback()
		log.Fatal(err)
	}

	// Commit transaction
	err = tx.Commit()
	if err != nil {
		log.Fatal(err)
	}

}
