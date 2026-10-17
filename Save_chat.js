import 'dotenv/config';
import mysql from 'mysql2/promise';
import express from 'express';
import cors from 'cors';

const app = express();
app.use(cors());
app.use(express.json());

// Kết nối CSDL MySQL
const db = mysql.createPool({
  host: process.env.DB_HOST || 'localhost',
  user: process.env.DB_USER || 'root',
  password: process.env.DB_PASS || '',
  database: process.env.DB_NAME || 'ai_chat_db',
  waitForConnections: true,
  connectionLimit: 10,
});

// Hàm giả lập AI & Lưu tin nhắn vào CSDL
async function handleChatAndSaveMock({ sessionId, userPrompt, modelName = 'gpt-4o' }) {
  const targetSessionId = sessionId ? Number(sessionId) : 1;
  const promptText = userPrompt || '';

  const [models] = await db.execute('SELECT id, input_cost_per_1k, output_cost_per_1k FROM ai_models WHERE model_name = ?', [modelName]);
  if (models.length === 0) throw new Error(`Model ${modelName} không tồn tại trong CSDL.`);
  
  const aiModel = models[0];

  // 1. Lưu câu hỏi của User
  await db.execute(`INSERT INTO chat_messages (session_id, role, content) VALUES (?, 'user', ?)`, [targetSessionId, promptText]);

  // 2. Tạo câu trả lời giả lập AI
  const latencyMs = Math.floor(Math.random() * 500) + 200;
  const assistantMessage = `[Server trả lời]: Tôi đã nhận được tin nhắn "${promptText}". Dữ liệu đã được lưu vào MySQL!`;
  
  const usage = {
    prompt_tokens: Math.floor(Math.random() * 20) + 10,
    completion_tokens: Math.floor(Math.random() * 40) + 20,
  };
  const totalTokens = usage.prompt_tokens + usage.completion_tokens;
  const estimatedCost = ((usage.prompt_tokens / 1000) * Number(aiModel.input_cost_per_1k)) + 
                        ((usage.completion_tokens / 1000) * Number(aiModel.output_cost_per_1k));

  // 3. Lưu câu trả lời của AI
  await db.execute(
    `INSERT INTO chat_messages (session_id, model_id, role, content, metadata, prompt_tokens, completion_tokens, total_tokens, estimated_cost, latency_ms) VALUES (?, ?, 'assistant', ?, ?, ?, ?, ?, ?, ?)`,
    [targetSessionId, aiModel.id, assistantMessage, JSON.stringify({ is_mock: true }), usage.prompt_tokens, usage.completion_tokens, totalTokens, estimatedCost, latencyMs]
  );

  // 4. Cập nhật tiêu đề phiên chat dựa trên tin nhắn đầu tiên
  const [sessionRows] = await db.execute('SELECT title FROM chat_sessions WHERE id = ?', [targetSessionId]);
  if (sessionRows.length > 0 && sessionRows[0].title === 'Cuộc trò chuyện mới') {
    const newTitle = promptText.length > 25 ? promptText.substring(0, 25) + '...' : promptText;
    await db.execute('UPDATE chat_sessions SET title = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?', [newTitle, targetSessionId]);
  } else {
    await db.execute('UPDATE chat_sessions SET updated_at = CURRENT_TIMESTAMP WHERE id = ?', [targetSessionId]);
  }

  return { reply: assistantMessage, tokens: totalTokens, cost: estimatedCost.toFixed(6), latency: latencyMs };
}

// ================= API ENDPOINTS =================

// 1. API Đăng nhập (Phân biệt Khách & Thành viên User)
app.post('/api/login', async (req, res) => {
  try {
    const role = req.body.role || 'user';
    const email = (req.body.email || '').trim();

    // CHẾ ĐỘ 1: ĐĂNG NHẬP KHÁCH (Tạo tài khoản tạm thời)
    if (role === 'guest' || !email) {
      const guestCode = Math.floor(1000 + Math.random() * 9000);
      const guestEmail = `guest_${guestCode}@system.local`;
      const guestName = `Khách #${guestCode}`;

      const [newUser] = await db.execute(
        'INSERT INTO users (email, name, role) VALUES (?, ?, "user")',
        [guestEmail, guestName]
      );

      const userId = newUser.insertId;

      const [newSession] = await db.execute(
        'INSERT INTO chat_sessions (user_id, title) VALUES (?, ?)',
        [userId, 'Cuộc trò chuyện mới']
      );

      return res.json({ 
        success: true, 
        user: { id: userId, email: guestEmail, name: guestName, isGuest: true },
        initialSessionId: newSession.insertId
      });
    }

    // CHẾ ĐỘ 2: ĐĂNG NHẬP THÀNH VIÊN (Nhập Email cá nhân)
    if (!email.includes('@')) {
      return res.status(400).json({ success: false, error: 'Vui lòng nhập Email hợp lệ có chứa ký tự @!' });
    }

    let [users] = await db.execute('SELECT id, email, name FROM users WHERE email = ?', [email]);
    
    // Nếu Email đã tồn tại -> Đăng nhập
    if (users.length > 0) {
      return res.json({ success: true, user: { ...users[0], isGuest: false } });
    }

    // Nếu Email mới -> Tự động đăng ký tài khoản User
    const userName = email.split('@')[0];
    const [newUser] = await db.execute(
      'INSERT INTO users (email, name, role) VALUES (?, ?, "user")',
      [email, userName]
    );

    const newUserId = newUser.insertId;
    
    // Tạo sẵn 1 phiên chat đầu cho User mới
    await db.execute('INSERT INTO chat_sessions (user_id, title) VALUES (?, ?)', [newUserId, 'Cuộc trò chuyện mới']);

    return res.json({
      success: true,
      user: { id: newUserId, email: email, name: userName, isGuest: false }
    });

  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// 2. API Xóa tài khoản Khách khi Đăng xuất
app.delete('/api/guest/:userId', async (req, res) => {
  try {
    const userId = Number(req.params.userId);
    if (!userId) return res.status(400).json({ success: false, error: 'ID không hợp lệ' });

    await db.execute(`
      DELETE FROM chat_messages 
      WHERE session_id IN (SELECT id FROM chat_sessions WHERE user_id = ?)
    `, [userId]);

    await db.execute('DELETE FROM chat_sessions WHERE user_id = ?', [userId]);
    await db.execute('DELETE FROM users WHERE id = ? AND email LIKE "guest_%@system.local"', [userId]);

    res.json({ success: true, message: 'Đã dọn dẹp dữ liệu Khách thành công' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// 3. API Lấy danh sách Session theo User ID
app.get('/api/sessions', async (req, res) => {
  try {
    const userId = req.query.userId ? Number(req.query.userId) : 1;
    const [sessions] = await db.execute('SELECT id, title, updated_at FROM chat_sessions WHERE user_id = ? ORDER BY updated_at DESC', [userId]);
    res.json({ success: true, data: sessions });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// 4. API Tạo phiên chat mới
app.post('/api/sessions', async (req, res) => {
  try {
    const userId = req.body.userId ? Number(req.body.userId) : 1;
    const defaultTitle = 'Cuộc trò chuyện mới';
    
    const [result] = await db.execute(
      'INSERT INTO chat_sessions (user_id, title) VALUES (?, ?)',
      [userId, defaultTitle]
    );

    res.json({ success: true, data: { id: result.insertId, title: defaultTitle } });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// 5. API Tải lịch sử chat
app.get('/api/chat/history', async (req, res) => {
  try {
    const sessionId = req.query.sessionId ? Number(req.query.sessionId) : 1;
    const [messages] = await db.execute(
      `SELECT role, content, total_tokens, estimated_cost, latency_ms FROM chat_messages WHERE session_id = ? ORDER BY created_at ASC`,
      [sessionId]
    );
    res.json({ success: true, data: messages });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

// 6. API Gửi tin nhắn
app.post('/api/chat', async (req, res) => {
  try {
    const { message, sessionId } = req.body;
    const targetSessionId = sessionId ? Number(sessionId) : 1;
    const result = await handleChatAndSaveMock({ sessionId: targetSessionId, userPrompt: message || '' });
    res.json({ success: true, data: result });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`🚀 Server API đang chạy tại: http://localhost:${PORT}`);
});