/**
 * 页面路由
 * 
 * API 端点：
 * GET    /api/pages/:notebookId          - 获取笔记本的所有页面
 * GET    /api/pages/page/:id             - 获取单个页面
 * POST   /api/pages                      - 创建页面
 * PUT    /api/pages/page/:id            - 更新页面 (绘图数据)
 * DELETE /api/pages/page/:id             - 删除页面
 */

const express = require('express');
const router = express.Router();
const { v4: uuidv4 } = require('uuid');
const { db } = require('../models/database');

/**
 * 获取笔记本的所有页面
 * GET /api/pages/:notebookId
 */
router.get('/:notebookId', (req, res) => {
  const { notebookId } = req.params;
  
  db.all('SELECT * FROM pages WHERE notebookId = ? ORDER BY pageOrder', [notebookId], (err, pages) => {
    if (err) {
      console.error('获取页面列表失败:', err);
      return res.status(500).json({ error: '获取页面列表失败' });
    }
    
    // 不返回大的 drawingData，只返回基本信息
    const pagesSummary = pages.map(p => ({
      id: p.id,
      notebookId: p.notebookId,
      pageOrder: p.pageOrder,
      createdAt: p.createdAt,
      modifiedAt: p.modifiedAt,
      hasDrawing: p.drawingData ? true : false,
      hasThumbnail: p.thumbnailData ? true : false
    }));
    
    res.json(pagesSummary);
  });
});

/**
 * 获取单个页面 (包含完整绘图数据)
 * GET /api/pages/page/:id
 */
router.get('/page/:id', (req, res) => {
  const { id } = req.params;
  
  db.get('SELECT * FROM pages WHERE id = ?', [id], (err, page) => {
    if (err) {
      console.error('获取页面失败:', err);
      return res.status(500).json({ error: '获取页面失败' });
    }
    
    if (!page) {
      return res.status(404).json({ error: '页面不存在' });
    }
    
    res.json(page);
  });
});

/**
 * 获取页面缩略图
 * GET /api/pages/thumbnail/:id
 */
router.get('/thumbnail/:id', (req, res) => {
  const { id } = req.params;
  
  db.get('SELECT thumbnailData FROM pages WHERE id = ?', [id], (err, page) => {
    if (err) {
      console.error('获取缩略图失败:', err);
      return res.status(500).json({ error: '获取缩略图失败' });
    }
    
    if (!page || !page.thumbnailData) {
      return res.status(404).json({ error: '缩略图不存在' });
    }
    
    res.set('Content-Type', 'image/png');
    res.send(page.thumbnailData);
  });
});

/**
 * 创建页面
 * POST /api/pages
 */
router.post('/', (req, res) => {
  const { notebookId, pageOrder } = req.body;
  
  if (!notebookId) {
    return res.status(400).json({ error: '笔记本 ID 不能为空' });
  }
  
  const id = uuidv4();
  const now = new Date().toISOString();
  
  // 获取当前最大页码
  db.get('SELECT MAX(pageOrder) as maxOrder FROM pages WHERE notebookId = ?', [notebookId], (err, result) => {
    if (err) {
      console.error('获取页码失败:', err);
      return res.status(500).json({ error: '获取页码失败' });
    }
    
    const order = pageOrder !== undefined ? pageOrder : ((result?.maxOrder ?? -1) + 1);
    
    db.run(`
      INSERT INTO pages (id, notebookId, pageOrder, createdAt, modifiedAt)
      VALUES (?, ?, ?, ?, ?)
    `, [id, notebookId, order, now, now], function(err) {
      if (err) {
        console.error('创建页面失败:', err);
        return res.status(500).json({ error: '创建页面失败' });
      }
      
      // 更新笔记本的修改时间
      db.run('UPDATE notebooks SET modifiedAt = ? WHERE id = ?', [now, notebookId], (err) => {
        if (err) console.error('更新笔记本时间失败:', err);
      });
      
      res.status(201).json({
        id,
        notebookId,
        pageOrder: order,
        createdAt: now,
        modifiedAt: now
      });
    });
  });
});

/**
 * 更新页面 (绘图数据)
 * PUT /api/pages/page/:id
 */
router.put('/page/:id', (req, res) => {
  const { id } = req.params;
  const { drawingData, thumbnailData } = req.body;
  const now = new Date().toISOString();
  
  // 如果 drawingData 是 base64 字符串，转换为 Buffer
  let drawingBuffer = null;
  let thumbnailBuffer = null;
  
  if (drawingData) {
    try {
      // 移除 data: 前缀
      const base64Data = drawingData.replace(/^data:.*?;base64,/, '');
      drawingBuffer = Buffer.from(base64Data, 'base64');
    } catch (e) {
      console.error('解析 drawingData 失败:', e);
    }
  }
  
  if (thumbnailData) {
    try {
      const base64Data = thumbnailData.replace(/^data:.*?;base64,/, '');
      thumbnailBuffer = Buffer.from(base64Data, 'base64');
    } catch (e) {
      console.error('解析 thumbnailData 失败:', e);
    }
  }
  
  const sql = `
    UPDATE pages
    SET drawingData = COALESCE(?, drawingData),
        thumbnailData = COALESCE(?, thumbnailData),
        modifiedAt = ?
    WHERE id = ?
  `;
  
  db.run(sql, [drawingBuffer, thumbnailBuffer, now, id], function(err) {
    if (err) {
      console.error('更新页面失败:', err);
      return res.status(500).json({ error: '更新页面失败' });
    }
    
    if (this.changes === 0) {
      return res.status(404).json({ error: '页面不存在' });
    }
    
    // 获取页面所属的笔记本并更新修改时间
    db.get('SELECT notebookId FROM pages WHERE id = ?', [id], (err, page) => {
      if (page) {
        db.run('UPDATE notebooks SET modifiedAt = ? WHERE id = ?', [now, page.notebookId], (err) => {
          if (err) console.error('更新笔记本时间失败:', err);
        });
      }
    });
    
    res.json({ id, message: '更新成功' });
  });
});

/**
 * 删除页面
 * DELETE /api/pages/page/:id
 */
router.delete('/page/:id', (req, res) => {
  const { id } = req.params;
  
  db.get('SELECT notebookId FROM pages WHERE id = ?', [id], (err, page) => {
    if (err || !page) {
      return res.status(404).json({ error: '页面不存在' });
    }
    
    const notebookId = page.notebookId;
    const now = new Date().toISOString();
    
    db.run('DELETE FROM pages WHERE id = ?', [id], function(err) {
      if (err) {
        console.error('删除页面失败:', err);
        return res.status(500).json({ error: '删除页面失败' });
      }
      
      // 更新笔记本的修改时间
      db.run('UPDATE notebooks SET modifiedAt = ? WHERE id = ?', [now, notebookId], (err) => {
        if (err) console.error('更新笔记本时间失败:', err);
      });
      
      res.json({ id, message: '删除成功' });
    });
  });
});

/**
 * 复制页面
 * POST /api/pages/copy
 */
router.post('/copy', (req, res) => {
  const { sourcePageId, targetNotebookId, targetOrder } = req.body;
  
  if (!sourcePageId || !targetNotebookId) {
    return res.status(400).json({ error: '源页面 ID 和目标笔记本 ID 不能为空' });
  }
  
  db.get('SELECT * FROM pages WHERE id = ?', [sourcePageId], (err, sourcePage) => {
    if (err || !sourcePage) {
      return res.status(404).json({ error: '源页面不存在' });
    }
    
    const newId = uuidv4();
    const now = new Date().toISOString();
    const order = targetOrder ?? (sourcePage.pageOrder + 1);
    
    db.run(`
      INSERT INTO pages (id, notebookId, drawingData, thumbnailData, pageOrder, createdAt, modifiedAt)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `, [newId, targetNotebookId, sourcePage.drawingData, sourcePage.thumbnailData, order, now, now], function(err) {
      if (err) {
        console.error('复制页面失败:', err);
        return res.status(500).json({ error: '复制页面失败' });
      }
      
      res.status(201).json({
        id: newId,
        notebookId: targetNotebookId,
        pageOrder: order,
        createdAt: now,
        modifiedAt: now
      });
    });
  });
});

module.exports = router;
