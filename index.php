<?php
$host = getenv('DB_HOST');
$user = getenv('DB_USER');
$pass = getenv('DB_PASS');
$db   = getenv('DB_NAME');

// Connect to the database
$conn = new mysqli($host, $user, $pass, $db);

// Check connection
if ($conn->connect_error) {
    die("DB Connection failed: " . $conn->connect_error);
}

// Create the visits table if it doesn't exist
$conn->query("CREATE TABLE IF NOT EXISTS visits (
    id INT PRIMARY KEY,
    count INT DEFAULT 0
)");

// Insert or increment the visit counter
$conn->query("INSERT INTO visits (id, count) VALUES (1, 1)
    ON DUPLICATE KEY UPDATE count = count + 1");

// Fetch and display the visit count
$result = $conn->query("SELECT count FROM visits WHERE id = 1");
$row = $result->fetch_assoc();

echo "Visit Count: " . $row['count'];
?>
