/**
 * 统计路由
 * 
 * API 端点：
 * GET /api/stats              - 获取全局统计
 * GET /api/stats/user         - 获取用户统计
 */

const express = require('express');
const router = express.Router();
const { verifyToken } = require('../middleware/auth');

/**
 * 获取全局统计
 * GET /api/stats
 */
router.get('/', (req, res) => {
  const stats = {
    totalNotebooks: 0,
    totalPages: 0,
    totalUsers: 0,
    storageUsed: 0
  };
  
  // 查询数据库获取统计
  const queries = [
    new Promise((resolve) => {
      db.get('SELECT COUNT(*) as count FROM notebooks', [], (err, row) => {
        stats.totalNotebooks = row?.count || 0;
        resolve();
      });
    }),
    new Promise((resolve) => {
      db.get('SELECT COUNT(*) as count FROM pages', [], (err, row) => {
        stats.totalPages = row?.count || 0;
        resolve();
      });
    })
  ];
  
  Promise.all(queries).then(() => {
    res.json(stats);
  });
});

/**
 * 获取用户统计
 * GET /api/stats/user
 */
router.get('/user', verifyToken, (req, res) => {
  const userId = req.userId;
  
  const stats = {
    notebookCount: 0,
    pageCount: 0,
    totalSize: 0,
    lastActive: null,
    storageUsed: 0
  };
  
  const queries = [
    new Promise((resolve) => {
      db.get('SELECT COUNT(*) as count FROM notebooks WHERE userId = ?', [userId], (err, row) => {
        stats.notebookCount = row?.count || 0;
        resolve();
      });
    }),
    new Promise((resolve) => {
      db.get(`
        SELECT COUNT(p.id) as count 
        FROM pages p 
        JOIN notebooks n ON p.notebookId = n.id 
        WHERE n.userId = ?
      `, [userId], (err, row) => {
        stats.pageCount = row?.count || 0;
        resolve();
      });
    }),
    new Promise((resolve) => {
      db.get(`
        SELECT SUM(LENGTH(p.drawingData)) as size 
        FROM pages p 
        JOIN notebooks n ON p.notebookId = n.id 
        WHERE n.userId = ?
      `, [userId], (err, row) => {
        stats.storageUsed = row?.size || 0;
        resolve();
      });
    }),
    new Promise((resolve) => {
      db.get('SELECT MAX(modifiedAt) as lastActive FROM notebooks WHERE userId = ?', [userId], (err, row) => {
        stats.lastActive = row?.lastActive;
        resolve();
      });
    })
  ];
  
  Promise.all(queries).then(() => {
    res.json(stats);
  });
});

/**
 * 获取笔记本统计
 * GET /api/stats/notebook/:id
 */
router.get('/notebook/:id', verifyToken, (req, res) => {
  const { id } = req.params;
  const userId = req.userId;
  
  const stats = {
    pageCount: 0,
    lastModified: null,
    size: 0,
    wordCount: 0
  };
  
  db.get('SELECT * FROM notebooks WHERE id = ? AND (userId = ? OR userId IS NULL)', [id, userId], (err, notebook) => {
    if (err || !notebook) {
      return res.status(404).json({ error: '笔记本不存在' });
    }
    
    db.all('SELECT * FROM pages WHERE notebookId = ?', [id], (err, pages) => {
      stats.pageCount = pages?.length || 0;
      
      let totalSize = 0;
      pages?.forEach(page => {
        totalSize += (page.drawingData?.length || 0);
        totalSize += (page.thumbnailData?.length || 0);
      });
      stats.size = totalSize;
      
      // 获取最后修改时间
      if (pages?.length > 0) {
        stats.lastModified = pages.reduce((max, p) => 
          new Date(p.modifiedAt) > new Date(max.modifiedAt) ? p : max
        ).modifiedAt;
      }
      
      res.json(stats);
    });
  });
});

/**
 * 获取存储使用情况
 * GET /api/stats/storage
 */
router.get('/storage', verifyToken, (req, res) => {
  const userId = req.userId;
  
  const storage = {
    used: 0,
    notebooks: [],
    limit: 5 * 1024 * 1024 * 1024, // 5GB 限制
    percent: 0
  };
  
  db.all(`
    SELECT n.id, n.title, n.coverColor, 
           SUM(LENGTH(p.drawingData)) as size,
           COUNT(p.id) as pageCount
    FROM notebooks n
    LEFT JOIN pages p ON n.id = p.notebookId
    WHERE n.userId = ?
    GROUP BY n.id
    ORDER BY size DESC
  `, [userId], (err, rows) => {
    if (err) {
      return res.status(500).json({ error: '查询失败' });
    }
    
    let totalSize = 0;
    storage.notebooks = rows?.map(row => {
      totalSize += row.size || 0;
      return {
        id: row.id,
        title: row.title,
        coverColor: row.coverColor,
        size: row.size || 0,
        pageCount: row.pageCount
      };
    }) || [];
    
    storage.used = totalSize;
    storage.percent = (totalSize / storage.limit) * 100;
    
    res.json(storage);
  });
});

module.exports = router;
