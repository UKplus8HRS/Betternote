/**
 * ClawNotes 后端 API 服务器
 * 
 * 功能：
 * - 笔记本 CRUD 操作
 * - 笔记页面管理
 * - 数据持久化 (SQLite)
 * 
 * 端口：3000
 */

const express = require('express');
const cors = require('cors');
const path = require('path');
const fs = require('fs');

// 确保数据目录存在
const dataDir = path.join(__dirname, 'data');
if (!fs.existsSync(dataDir)) {
  fs.mkdirSync(dataDir, { recursive: true });
}

// 导入路由
const notebooksRouter = require('./routes/notebooks');
const pagesRouter = require('./routes/pages');
const { initDatabase } = require('./models/database');

const app = express();
const PORT = process.env.PORT || 3000;

// 中间件
app.use(cors());
app.use(express.json({ limit: '50mb' })); // 支持大文件 (绘图数据)
app.use(express.urlencoded({ extended: true, limit: '50mb' }));

// 静态文件 (如果有前端页面)
app.use(express.static(path.join(__dirname, 'public')));

// API 路由
app.use('/api/notebooks', notebooksRouter);
app.use('/api/pages', pagesRouter);

// 健康检查
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// 根路径
app.get('/', (req, res) => {
  res.json({
    name: 'ClawNotes API',
    version: '1.0.0',
    endpoints: {
      notebooks: '/api/notebooks',
      pages: '/api/pages',
      health: '/health'
    }
  });
});

// 错误处理中间件
app.use((err, req, res, next) => {
  console.error('服务器错误:', err);
  res.status(500).json({ error: '服务器内部错误', message: err.message });
});

// 初始化数据库并启动服务器
async function startServer() {
  try {
    await initDatabase();
    
    app.listen(PORT, () => {
      console.log(`
╔════════════════════════════════════════╗
║       ClawNotes API 服务器             ║
║       端口: http://localhost:${PORT}       ║
╚════════════════════════════════════════╝
      `);
    });
  } catch (error) {
    console.error('启动服务器失败:', error);
    process.exit(1);
  }
}

startServer();

module.exports = app;
