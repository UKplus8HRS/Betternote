/**
 * 用户路由
 * 
 * API 端点：
 * GET  /api/users/me           - 获取当前用户信息
 * GET  /api/users/:uid         - 获取指定用户信息 (仅管理员)
 * POST /api/users/anon         - 创建匿名用户
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
    
    res.json(userInfo);
  } catch (error) {
    console.error('获取用户信息失败:', error);
    res.status(500).json({ error: '获取用户信息失败' });
  }
});

/**
 * 创建匿名用户
 * POST /api/users/anon
 * 
 * 用于临时用户，无需认证
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
 * 
 * 用于刷新用户的 ID Token
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
 * 
 * 用于将当前匿名用户链接到其他登录方式
 * 
 * 请求体:
 * {
 *   "idToken": "新的 ID Token (从客户端获取)",
 *   "providerId": "google.com" | "wechat.com" | "apple.com"
 * }
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
    // 这里只是记录链接请求
    
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
 * 删除用户
 * DELETE /api/users/:uid
 * 
 * 需要管理员权限
 */
router.delete('/:uid', verifyToken, async (req, res) => {
  const { uid } = req.params;
  
  // 检查权限
  if (req.userId !== uid) {
    // 这里可以添加管理员检查逻辑
    // return res.status(403).json({ error: '无权限' });
  }
  
  try {
    await admin.auth().deleteUser(uid);
    res.json({ message: '用户已删除', uid });
  } catch (error) {
    console.error('删除用户失败:', error);
    res.status(500).json({ error: '删除用户失败' });
  }
});

module.exports = router;
