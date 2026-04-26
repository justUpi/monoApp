<?php

include 'config.php'; 

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *'); 

if ($_SERVER['REQUEST_METHOD'] === 'POST') {
    
    $title = $_POST['title'] ?? null;
    $importance = $_POST['importance_level'] ?? 1; 
    $userId = $_POST['user_id'] ?? null;

    if (!$title || !$userId) {
        echo json_encode([
            "status" => "error", 
            "message" => "Missing title or user identification."
        ]);
        exit;
    }

    try {

        $sql = "INSERT INTO tasks (title, importance_level, user_id, is_completed) 
                VALUES (:title, :importance, :user_id, false)";
        
        $stmt = $pdo->prepare($sql);
        
        $stmt->execute([
            ':title' => $title,
            ':importance' => (int)$importance,
            ':user_id' => $userId
        ]);

        echo json_encode([
            "status" => "success", 
            "message" => "Task saved to Mono successfully!"
        ]);

    } catch (PDOException $e) {

        echo json_encode([
            "status" => "error", 
            "message" => "Database Error: " . $e->getMessage()
        ]);
    }
} else {
    echo json_encode([
        "status" => "error", 
        "message" => "Only POST requests are allowed."
    ]);
}
?>