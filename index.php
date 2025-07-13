<?php
$host = getenv('DB_HOST');
$user = getenv('DB_USER');
$pass = getenv('DB_PASS');
$db   = getenv('DB_NAME');

$conn = new mysqli($host, $user, $pass, $db);

if ($conn->connect_error) {
    die("Connection failed: " . $conn->connect_error);
}

$conn->query("CREATE TABLE IF NOT EXISTS counter (visits INT)");
$conn->query("INSERT INTO counter (visits) VALUES (1) ON DUPLICATE KEY UPDATE visits = visits + 1");

$result = $conn->query("SELECT visits FROM counter");
$row = $result->fetch_assoc();

echo "<h1>Visit count: " . $row['visits'] . "</h1>";

$conn->close();
?>
