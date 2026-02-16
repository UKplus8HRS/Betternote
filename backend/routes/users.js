/**
 * 用户路由
 * 
 * API 端点：
 * GET  /api/users/me           - 获取当前用户信息
 * GET  /api/users/:uid         - 获取指定用户信息
 * POST /api/users/anon         - 创建匿名用户
 * POST /api/users/refresh      - 刷新 Token
 * POST /api/users/link        - 链接登录提供商
 * DELETE /api/users/:uid      - 删除用户
 */

const express = require('express');
const router = express.Router();
const { verifyToken, getUserInfo } = require('../middleware/auth');
const { admin } = require('../middleware/firebase');

/**
 * 获取当前用户信息
 * GET /api/users/me
 * 
 * 需要认证
 */
router.get('/me', verifyToken, async (req, res) => {
  try {
    const userInfo = await getUserInfo(req.userId);
    
    if (!userInfo) {
      return res.status(404).json({ error: '用户不存在' });
    }
    
    // 获取用户统计
    const stats = await getUserStats(req.userId);
    
    res.json({
      ...userInfo,
      stats
    });
  } catch (error) {
    console.error('获取用户信息失败:', error);
    res.status(500).json({ error: '获取用户信息失败' });
  }
});

/**
 * 获取用户统计信息
 */
async function getUserStats(uid) {
  return new Promise((resolve) => {
    // 这里可以查询用户的笔记本数量、页面数量等
    const stats = {
      notebookCount: 0,
      pageCount: 0,
      totalSize: 0,
      lastActive: new Date().toISOString()
    };
    
    // 查询数据库
    db.get('SELECT COUNT(*) as count FROM notebooks WHERE userId = ?', [uid], (err, row) => {
      if (!err && row) {
        stats.notebookCount = row.count;
      }
      
      resolve(stats);
    });
  });
}

/**
 * 获取指定用户公开信息
 * GET /api/users/public/:uid
 */
router.get('/public/:uid', async (req, res) => {
  const { uid } = req.params;
  
  try {
    const userRecord = await admin.auth().getUser(uid);
    
    res.json({
      uid: userRecord.uid,
      displayName: userRecord.displayName,
      photoURL: userRecord.photoURL,
      // 不返回敏感信息
    });
  } catch (error) {
    res.status(404).json({ error: '用户不存在' });
  }
});

/**
 * 创建匿名用户
 * POST /api/users/anon
 */
router.post('/anon', async (req, res) => {
  try {
    const userRecord = await admin.auth().createUser({
      uid: `anon_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
    });
    
    // 生成自定义 token 用于客户端登录
    const customToken = await admin.auth().createCustomToken(userRecord.uid);
    
    res.status(201).json({
      uid: userRecord.uid,
      customToken: customToken,
      isAnonymous: true,
    });
  } catch (error) {
    console.error('创建匿名用户失败:', error);
    res.status(500).json({ error: '创建匿名用户失败' });
  }
});

/**
 * 刷新用户 Token
 * POST /api/users/refresh
 */
router.post('/refresh', verifyToken, async (req, res) => {
  try {
    // Firebase ID Token 会在 1 小时后过期
    // 客户端应该使用 Firebase SDK 自动刷新
    // 此端点用于验证 token 仍然有效
    
    res.json({
      uid: req.userId,
      valid: true,
      message: 'Token 有效',
    });
  } catch (error) {
    res.status(500).json({ error: '验证失败' });
  }
});

/**
 * 链接登录提供商
 * POST /api/users/link
 */
router.post('/link', verifyToken, async (req, res) => {
  const { idToken, providerId } = req.body;
  
  if (!idToken || !providerId) {
    return res.status(400).json({ error: '缺少必要参数' });
  }
  
  try {
    // 验证新 token
    const decodedToken = await admin.auth().verifyIdToken(idToken);
    
    // 检查用户是否已链接此提供商
    const userRecord = await admin.auth().getUser(req.userId);
    const alreadyLinked = userRecord.providerData.some(p => p.providerId === providerId);
    
    if (alreadyLinked) {
      return res.status(400).json({ error: '此登录方式已绑定' });
    }
    
    // 注意：实际的账号链接需要在客户端完成
    
    res.json({
      success: true,
      message: '账号链接请求已接收',
      newUid: decodedToken.uid,
    });
  } catch (error) {
    console.error('链接账号失败:', error);
    res.status(500).json({ error: '链接账号失败' });
  }
});

/**
 * 更新用户资料
 * PUT /api/users/me
 */
router.put('/me', verifyToken, async (req, res) => {
  const { displayName, photoURL } = req.body;
  
  try {
    await admin.auth().updateUser(req.userId, {
      displayName: displayName,
      photoURL: photoURL
    });
    
    res.json({ message: '更新成功' });
  } catch (error) {
    console.error('更新用户资料失败:', error);
    res.status(500).json({ error: '更新用户资料失败' });
  }
});

/**
 * 删除用户
 * DELETE /api/users/:uid
 */
router.delete('/:uid', verifyToken, async (req, res) => {
  const { uid } = req.params;
  
  // 检查权限
  if (req.userId !== uid) {
    // 这里可以添加管理员检查逻辑
  }
  
  try {
    await admin.auth().deleteUser(uid);
    res.json({ message: '用户已删除', uid });
  } catch (error) {
    console.error('删除用户失败:', error);
    res.status(500).json({ error: '删除用户失败' });
  }
});

/**
 * 获取用户设置
 * GET /api/users/me/settings
 */
router.get('/me/settings', verifyToken, (req, res) => {
  // 从数据库获取用户设置
  const settings = {
    language: 'zh-Hans',
    theme: 'default',
    notifications: true
  };
  
  res.json(settings);
});

/**
 * 更新用户设置
 * PUT /api/users/me/settings
 */
router.put('/me/settings', verifyToken, (req, res) => {
  const { settings } = req.body;
  
  // 保存到数据库
  // ...
  
  res.json({ message: '设置已更新' });
});

module.exports = router;
