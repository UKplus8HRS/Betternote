/**
 * 笔记本路由
 * 
 * API 端点：
 * GET    /api/notebooks          - 获取所有笔记本
 * GET    /api/notebooks/:id      - 获取单个笔记本
 * POST   /api/notebooks          - 创建笔记本
 * PUT    /api/notebooks/:id      - 更新笔记本
 * DELETE /api/notebooks/:id      - 删除笔记本
 */

const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const { db } = require('../models/database');

/**
 * 获取所有笔记本
 * GET /api/notebooks
 */
router.get('/', (req, res) => {
  const { userId } = req.query;

  let sql = 'SELECT * FROM notebooks';
  let params = [];

  if (userId) {
    sql += ' WHERE userId = ?';
    params.push(userId);
  }

  sql += ' ORDER BY modifiedAt DESC';

  db.all(sql, params, (err, notebooks) => {
    if (err) {
      console.error('获取笔记本失败:', err);
      return res.status(500).json({ error: '获取笔记本失败' });
    }

    res.json(notebooks);
  });
});

/**
 * 获取单个笔记本 (包含所有页面)
 * GET /api/notebooks/:id
 */
router.get('/:id', (req, res) => {
  const { id } = req.params;

  db.get('SELECT * FROM notebooks WHERE id = ?', [id], (err, notebook) => {
    if (err) {
      console.error('获取笔记本失败:', err);
      return res.status(500).json({ error: '获取笔记本失败' });
    }

    if (!notebook) {
      return res.status(404).json({ error: '笔记本不存在' });
    }

    // 获取笔记本的所有页面
    db.all('SELECT * FROM pages WHERE notebookId = ? ORDER BY pageOrder', [id], (err, pages) => {
      if (err) {
        console.error('获取页面失败:', err);
        return res.status(500).json({ error: '获取页面失败' });
      }

      notebook.pages = pages;
      res.json(notebook);
    });
  });
});

/**
 * 创建笔记本
 * POST /api/notebooks
 */
router.post('/', (req, res) => {
  const { title, coverColor, userId } = req.body;

  if (!title) {
    return res.status(400).json({ error: '笔记本标题不能为空' });
  }

  const id = uuidv4();
  const now = new Date().toISOString();

  const sql = `
    INSERT INTO notebooks (id, title, coverColor, createdAt, modifiedAt, userId)
    VALUES (?, ?, ?, ?, ?, ?)
  `;

  db.run(sql, [id, title, coverColor || 'blue', now, now, userId || null], function (err) {
    if (err) {
      console.error('创建笔记本失败:', err);
      return res.status(500).json({ error: '创建笔记本失败' });
    }

    // 创建第一个空白页面
    const pageId = uuidv4();
    db.run(`
      INSERT INTO pages (id, notebookId, pageOrder, createdAt, modifiedAt)
      VALUES (?, ?, ?, ?, ?)
    `, [pageId, id, 0, now, now], (err) => {
      if (err) {
        console.error('创建初始页面失败:', err);
      }
    });

    res.status(201).json({
      id,
      title,
      coverColor: coverColor || 'blue',
      createdAt: now,
      modifiedAt: now,
      pages: [{ id: pageId, notebookId: id, pageOrder: 0 }]
    });
  });
});

/**
 * 更新笔记本
 * PUT /api/notebooks/:id
 */
router.put('/:id', (req, res) => {
  const { id } = req.params;
  const { title, coverColor } = req.body;
  const now = new Date().toISOString();

  const sql = `
    UPDATE notebooks
    SET title = COALESCE(?, title),
        coverColor = COALESCE(?, coverColor),
        modifiedAt = ?
    WHERE id = ?
  `;

  db.run(sql, [title, coverColor, now, id], function (err) {
    if (err) {
      console.error('更新笔记本失败:', err);
      return res.status(500).json({ error: '更新笔记本失败' });
    }

    if (this.changes === 0) {
      return res.status(404).json({ error: '笔记本不存在' });
    }

    res.json({ id, message: '更新成功' });
  });
});

/**
 * 删除笔记本
 * DELETE /api/notebooks/:id
 */
router.delete('/:id', (req, res) => {
  const { id } = req.params;

  // 使用 serialize 保证顺序，但只发送一次响应
  let responseSent = false;

  db.serialize(() => {
    db.run('DELETE FROM pages WHERE notebookId = ?', [id], (err) => {
      if (err) {
        console.error('删除页面失败:', err);
        if (!responseSent) {
          responseSent = true;
          return res.status(500).json({ error: '删除页面失败' });
        }
      }
    });

    db.run('DELETE FROM notebooks WHERE id = ?', [id], function (err) {
      if (responseSent) return;
      responseSent = true;

      if (err) {
        console.error('删除笔记本失败:', err);
        return res.status(500).json({ error: '删除笔记本失败' });
      }

      if (this.changes === 0) {
        return res.status(404).json({ error: '笔记本不存在' });
      }

      res.json({ id, message: '删除成功' });
    });
  });
});

module.exports = router;
