/**
 * Firebase 初始化
 * 
 * 使用方法：
 * 1. 在 Firebase Console 创建项目
 * 2. 下载服务账号密钥文件 (serviceAccountKey.json)
 * 3. 将文件重命名为 firebase-service-account.json 放在 backend 目录
 * 4. 配置微信登录需要在 Firebase Console 中添加
 * 
 * 支持的登录方式：
 * - Apple ID
 * - Google
 * - WeChat (需要微信开放平台配置)
 * - Email/Password
 * - Anonymous (匿名登录)
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// 服务账号文件路径
const serviceAccountPath = path.join(__dirname, 'firebase-service-account.json');

// 检查是否存在服务账号文件
let serviceAccount;
if (fs.existsSync(serviceAccountPath)) {
  serviceAccount = require(serviceAccountPath);
} else {
  console.warn('⚠️  Firebase 服务账号文件不存在!');
  console.warn('   请下载 serviceAccountKey.json 并重命名为 firebase-service-account.json');
  console.warn('   或者设置环境变量 FIREBASE_CONFIG');
}

// 初始化 Firebase Admin
let initialized = false;

function initializeFirebase() {
  if (initialized) {
    return admin;
  }
  
  if (serviceAccount) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });
    initialized = true;
    console.log('✓ Firebase Admin SDK 初始化成功');
  } else {
    // 尝试从环境变量初始化
    const firebaseConfig = process.env.FIREBASE_CONFIG;
    if (firebaseConfig) {
      try {
        const config = JSON.parse(firebaseConfig);
        admin.initializeApp({
          credential: admin.credential.cert(config),
        });
        initialized = true;
        console.log('✓ Firebase Admin SDK 初始化成功 (从环境变量)');
      } catch (e) {
        console.error('从环境变量初始化 Firebase 失败:', e);
      }
    }
  }
  
  return admin;
}

// 立即初始化
const adminSDK = initializeFirebase();

module.exports = {
  admin: adminSDK,
  initializeFirebase,
};

/**
 * Firebase 提供商映射
 * 
 * firebase-provider-id:
 * - apple.com: Apple ID
 * - google.com: Google
 * - wechat.com: WeChat
 * - password: Email/Password
 * - anonymous: Anonymous
 */
const providerMap = {
  'apple.com': 'Apple',
  'google.com': 'Google',
  'wechat.com': 'WeChat',
  'password': 'Email',
  'anonymous': '匿名',
};

/**
 * 获取提供商显示名称
 */
function getProviderName(providerId) {
  return providerMap[providerId] || providerId;
}

module.exports.getProviderName = getProviderName;
