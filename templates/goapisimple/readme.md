# Go API Simple

## If you want to create a user with a specific ID, you can use the following command:
curl -X POST http://localhost:8080/api/users -H "Content-Type: application/json" -d '{
    "id": "1",
    "username": "John Doe",
    "email": "john@example.com",
    "firstName": "John",
    "lastName": "Doe"
  }'

## If you want to create a user with auto-generated ID, you can use the following command:
curl -X POST http://localhost:8080/api/users -H "Content-Type: application/json" -d '{
    "username": "Jane Doe",
    "email": "jane@example.com",
    "firstName": "Jane",
    "lastName": "Doe"
  }'

curl -X GET http://localhost:8080/api/users

curl -X GET http://localhost:8080/api/users/1

curl -X PUT http://localhost:8080/api/users/1 -H "Content-Type: application/json" -d '{
    "username": "John Doey",
    "email": "john@example.com",
    "firstName": "John",
    "lastName": "Doey"
  }'

curl -X DELETE http://localhost:8080/api/users/1

