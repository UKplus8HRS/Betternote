/**
 * SQLite 数据库初始化
 * 
 * 创建必要的表：
 * - notebooks: 笔记本
 * - pages: 笔记页面
 */

const sqlite3 = require('sqlite3').verbose();
const path = require('path');

const dbPath = path.join(__dirname, '..', 'data', 'clawnotes.db');
const db = new sqlite3.Database(dbPath);

// 初始化数据库
function initDatabase() {
  return new Promise((resolve, reject) => {
    db.serialize(() => {
      // 创建笔记本表
      db.run(`
        CREATE TABLE IF NOT EXISTS notebooks (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          coverColor TEXT DEFAULT 'blue',
          createdAt TEXT NOT NULL,
          modifiedAt TEXT NOT NULL,
          userId TEXT
        )
      `, (err) => {
        if (err) {
          console.error('创建 notebooks 表失败:', err);
          reject(err);
          return;
        }
        console.log('✓ notebooks 表创建成功');
      });

      // 创建页面表
      db.run(`
        CREATE TABLE IF NOT EXISTS pages (
          id TEXT PRIMARY KEY,
          notebookId TEXT NOT NULL,
          drawingData BLOB,
          thumbnailData BLOB,
          pageOrder INTEGER DEFAULT 0,
          createdAt TEXT NOT NULL,
          modifiedAt TEXT NOT NULL,
          FOREIGN KEY (notebookId) REFERENCES notebooks(id) ON DELETE CASCADE
        )
      `, (err) => {
        if (err) {
          console.error('创建 pages 表失败:', err);
          reject(err);
          return;
        }
        console.log('✓ pages 表创建成功');
      });

      // 创建索引
      db.run(`
        CREATE INDEX IF NOT EXISTS idx_pages_notebookId ON pages(notebookId)
      `, (err) => {
        if (err) {
          console.error('创建索引失败:', err);
          reject(err);
          return;
        }
        console.log('✓ 索引创建成功');
      });

      console.log('✓ 数据库初始化完成');
      resolve();
    });
  });
}

// 导出数据库和初始化函数
module.exports = {
  db,
  initDatabase
};
