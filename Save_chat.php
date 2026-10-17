<?php
// 1. Cấu hình kết nối MySQL PDO
$host = 'localhost';
$db   = 'ai_chat_db';
$user = 'root';
$pass = '';
$charset = 'utf8mb4';

$dsn = "mysql:host=$host;dbname=$db;charset=$charset";
$options = [
    PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
    PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
];

try {
    $pdo = new PDO($dsn, $user, $pass, $options);
} catch (\PDOException $e) {
    throw new \PDOException($e->getMessage(), (int)$e->getCode());
}

/**
 * Hàm gọi OpenAI API (curl) và lưu lịch sử kèm Token Usage
 */
function handleChatAndSavePDO($pdo, $sessionId, $userPrompt, $modelName = 'gpt-4o') {
    $apiKey = getenv('OPENAI_API_KEY');
    $startTime = microtime(true);

    // A. Lấy thông tin Model & Đơn giá từ CSDL
    $stmtModel = $pdo->prepare("SELECT id, input_cost_per_1k, output_cost_per_1k FROM ai_models WHERE model_name = ? AND is_active = TRUE");
    $stmtModel->execute([$modelName]);
    $aiModel = $stmtModel->fetch();

    if (!$aiModel) {
        die("Model {$modelName} không tồn tại hoặc bị khóa.");
    }

    // B. Lưu tin nhắn của User
    $stmtUserMsg = $pdo->prepare("INSERT INTO chat_messages (session_id, role, content) VALUES (?, 'user', ?)");
    $stmtUserMsg->execute([$sessionId, $userPrompt]);

    // C. Gọi OpenAI API bằng cURL
    $ch = curl_init('https://api.openai.com/v1/chat/completions');
    $payload = json_encode([
        'model' => $modelName,
        'messages' => [
            ['role' => 'user', 'content' => $userPrompt]
        ]
    ]);

    curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
    curl_setopt($ch, CURLOPT_POST, true);
    curl_setopt($ch, CURLOPT_POSTFIELDS, $payload);
    curl_setopt($ch, CURLOPT_HTTPHEADER, [
        'Content-Type: application/json',
        'Authorization: Bearer ' . $apiKey
    ]);

    $response = curl_exec($ch);
    curl_close($ch);

    $endTime = microtime(true);
    $latencyMs = round(($endTime - $startTime) * 1000);

    $resData = json_decode($response, true);
    
    if (isset($resData['error'])) {
        die("Lỗi API OpenAI: " . $resData['error']['message']);
    }

    $assistantMessage = $resData['choices'][0]['message']['content'];
    $promptTokens     = $resData['usage']['prompt_tokens'];
    $completionTokens = $resData['usage']['completion_tokens'];

    // D. Tính toán chi phí (USD)
    $promptCost    = ($promptTokens / 1000) * (float)$aiModel['input_cost_per_1k'];
    $completionCost= ($completionTokens / 1000) * (float)$aiModel['output_cost_per_1k'];
    $estimatedCost = $promptCost + $completionCost;

    $metadata = json_encode([
        'finish_reason' => $resData['choices'][0]['finish_reason'] ?? 'stop',
        'system_fingerprint' => $resData['system_fingerprint'] ?? null
    ]);

    // E. Lưu tin nhắn Assistant & Token Usage
    $stmtInsertBot = $pdo->prepare("
        INSERT INTO chat_messages 
            (session_id, model_id, role, content, metadata, prompt_tokens, completion_tokens, estimated_cost, latency_ms) 
        VALUES 
            (?, ?, 'assistant', ?, ?, ?, ?, ?, ?)
    ");

    $stmtInsertBot->execute([
        $sessionId,
        $aiModel['id'],
        $assistantMessage,
        $metadata,
        $promptTokens,
        $completionTokens,
        $estimatedCost,
        $latencyMs
    ]);

    // F. Cập nhật Session updated_at
    $pdo->prepare("UPDATE chat_sessions SET updated_at = CURRENT_TIMESTAMP WHERE id = ?")->execute([$sessionId]);

    return [
        'reply' => $assistantMessage,
        'prompt_tokens' => $promptTokens,
        'completion_tokens' => $completionTokens,
        'estimated_cost' => $estimatedCost,
        'latency_ms' => $latencyMs
    ];
}

// --- DỮ LIỆU ĐẦU VÀO MẪU ĐỂ KHỞI TẠO BẢNG AI_MODELS TRƯỚC KHI CHẠY ---
/*
INSERT INTO ai_models (model_name, provider, input_cost_per_1k, output_cost_per_1k) 
VALUES ('gpt-4o', 'OpenAI', 0.002500, 0.010000);
*/

// CHẠY THỬ (với session_id = 1 đã có sẵn trong bảng chat_sessions)
// $result = handleChatAndSavePDO($pdo, 1, "Viết cho tôi 1 câu chúc ngày mới năng động.");
// print_r($result);
?>