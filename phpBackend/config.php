<?php
// phpBackend/config.php

$host = 'postgresql://postgres:[rUWnz5t9TiJiyg]@db.hhcgdgbipqmusqvunbbj.supabase.co:5432/postgres'; 
$port = '5432';
$db_name = 'mono';
$username = 'mono';
$password = 'rUWnz5t9TiJiyg0N'; 

try {
    $dsn = "pgsql:host=$host;port=$port;dbname=$db_name";

    // 3. Initialize PDO
    $pdo = new PDO($dsn, $username, $password, [
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ]);

} catch (PDOException $e) {
    // 4. Handle connection errors
    header('Content-Type: application/json');
    echo json_encode(["status" => "error", "message" => "Connection failed: " . $e->getMessage()]);
    exit;
}
?>