/**
 * Firebase 认证中间件
 * 
 * 支持的登录方式：
 * - Apple ID (通过 Firebase)
 * - Google (通过 Firebase)
 * - WeChat (通过 Firebase)
 * - Email/Password (通过 Firebase)
 * 
 * 使用方法：
 * 在需要认证的路由中引入此中间件
 * const { verifyToken } = require('../middleware/auth');
 * router.get('/protected', verifyToken, (req, res) => { ... });
 */

const { admin } = require('./firebase');

/**
 * 验证 Firebase ID Token
 * 
 * @param {string} token - Firebase ID Token
 * @returns {Promise<object>} decoded token
 */
async function verifyIdToken(token) {
  try {
    const decodedToken = await admin.auth().verifyIdToken(token);
    return decodedToken;
  } catch (error) {
    console.error('Token 验证失败:', error);
    throw error;
  }
}

/**
 * Express 中间件：验证用户 token
 */
function verifyToken(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: '未授权访问', message: '缺少认证 token' });
  }
  
  const token = authHeader.split('Bearer ')[1];
  
  verifyIdToken(token)
    .then((decodedToken) => {
      req.user = decodedToken;
      req.userId = decodedToken.uid;
      next();
    })
    .catch((error) => {
      return res.status(401).json({ error: '认证失败', message: '无效的 token' });
    });
}

/**
 * 可选的认证中间件
 * 如果有 token 则验证，没有则允许继续
 */
function optionalAuth(req, res, next) {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return next(); // 无 token，继续
  }
  
  const token = authHeader.split('Bearer ')[1];
  
  verifyIdToken(token)
    .then((decodedToken) => {
      req.user = decodedToken;
      req.userId = decodedToken.uid;
    })
    .catch((error) => {
      console.log('Token 验证失败，继续作为游客:', error.message);
    })
    .finally(() => {
      next();
    });
}

/**
 * 获取用户信息
 * 通过 Firebase Auth 获取用户详情
 */
async function getUserInfo(uid) {
  try {
    const userRecord = await admin.auth().getUser(uid);
    return {
      uid: userRecord.uid,
      email: userRecord.email,
      displayName: userRecord.displayName,
      photoURL: userRecord.photoURL,
      providerData: userRecord.providerData,
      createdAt: userRecord.metadata.creationTime,
    };
  } catch (error) {
    console.error('获取用户信息失败:', error);
    return null;
  }
}

module.exports = {
  verifyToken,
  optionalAuth,
  verifyIdToken,
  getUserInfo,
};
