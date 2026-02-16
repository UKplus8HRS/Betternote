# ClawNotes 后端部署教程

本教程将帮助你将 ClawNotes 后端部署到云服务器，让其他人也能使用。

---

## 🏗️ 部署选项

| 平台 | 难度 | 成本 | 推荐 |
|------|------|------|------|
| Railway | ⭐ | $5/月 | ✅ 推荐 |
| Render | ⭐ | 免费 | ✅ 推荐 |
| Heroku | ⭐ | 免费 | ✅ |
| VPS (DigitalOcean) | ⭐⭐ | $4/月 | ✅ |
| Vercel | ⭐ | 免费 | ⚠️ 需要适配 |

---

## 🚀 快速部署 (Railway)

### 步骤 1: 准备代码

1. 创建 ` Railway.json` 配置文件:

```json
{
  "$schema": "https://railway.app/schema.json",
  "build": {
    "builder": "NIXPACKS_NODE"
  },
  "deploy": {
    "numInstances": 1,
    "restartPolicyType": "ON_FAILURE",
    "restartPolicyMaxRetries": 10
  }
}
```

### 步骤 2: 推送到 GitHub

确保代码在 GitHub 上:

```bash
git add .
git commit -m "Prepare for deployment"
git push origin master
```

### 步骤 3: 部署到 Railway

1. 访问 [Railway.app](https://railway.app)
2. 用 GitHub 登录
3. 点击 "New Project"
4. 选择 "Deploy from GitHub repo"
5. 选择 `Betternote` 仓库
6. 找到 `backend` 目录并选择
7. 点击 "Deploy"

### 步骤 4: 配置环境变量

在 Railway 项目设置中添加:

```
PORT=3000
NODE_ENV=production
```

---

## 🚀 快速部署 (Render)

### 步骤 1: 创建 render.yaml

```yaml
services:
  - type: web
    name: betternotes-api
    env: node
    region: london
    buildCommand: cd backend && npm install
    startCommand: cd backend && npm start
    envVars:
      - key: NODE_ENV
        value: production
      - key: PORT
        value: 10000
```

### 步骤 2: 部署

1. 访问 [Render.com](https://render.com)
2. 用 GitHub 登录
3. 点击 "New" → "Web Service"
4. 选择 GitHub 仓库
5. 配置:
   - Build Command: `cd backend && npm install`
   - Start Command: `cd backend && npm start`
6. 点击 "Deploy"

---

## 🖥️ VPS 部署 (DigitalOcean)

### 步骤 1: 创建 Droplet

1. 注册 [DigitalOcean](https://digitalocean.com)
2. 创建新的 Droplet (Ubuntu 20.04)
3. 记录 IP 地址

### 步骤 2: 连接服务器

```bash
ssh root@你的IP
```

### 步骤 3: 安装 Node.js

```bash
# 安装 Node.js
curl -fsSL https://deb.nodesource.com/setup_18.x | bash -
apt-get install -y nodejs

# 验证
node -v
npm -v
```

### 步骤 4: 安装 Git 和 Nginx

```bash
apt-get update
apt-get install -y git nginx certbot python3-certbot-nginx
```

### 步骤 5: 克隆项目

```bash
cd /var/www
git clone https://github.com/UKplus8HRS/Betternote.git
cd Betternote/backend
npm install
```

### 步骤 6: 配置 Systemd 服务

创建 `/etc/systemd/system/clawnotes.service`:

```ini
[Unit]
Description=ClawNotes API
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/var/www/Betternote/backend
ExecStart=/usr/bin/npm start
Restart=always

[Install]
WantedBy=multi-user.target
```

启动服务:

```bash
systemctl daemon-reload
systemctl start clawnotes
systemctl enable clawnotes
```

### 步骤 7: 配置 Nginx

创建 `/etc/nginx/sites-available/clawnotes`:

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

启用:

```bash
ln -s /etc/nginx/sites-available/clawnotes /etc/nginx/sites-enabled/
nginx -t
systemctl reload nginx
```

### 步骤 8: 配置 HTTPS (可选)

```bash
certbot --nginx -d your-domain.com
```

---

## 🔧 配置 Firebase

### 步骤 1: 获取服务账号

1. 打开 [Firebase Console](https://console.firebase.google.com)
2. 选择项目 → 项目设置 → 服务账号
3. 点击 "生成新的私钥"
4. 下载 JSON 文件

### 步骤 2: 配置环境变量

在部署平台添加:

```
FIREBASE_CONFIG={"type":"service_account","project_id":"your-project",...}
```

---

## 📱 前端配置

### 修改 API 地址

在前端代码中修改 API 地址:

```swift
// CloudKitManager.swift 或 API 客户端
let baseURL = "https://your-domain.com/api"
```

---

## 🐛 常见问题

### 1. 端口被占用

```bash
# 查看端口占用
lsof -i :3000

# 杀死进程
kill -9 <PID>
```

### 2. 内存不足

```bash
# 查看内存
free -h

# 添加 swap
fallocate -l 2G /swapfile
chmod 600 /swapfile
mkswap /swapfile
swapon /swapfile
```

### 3. 数据库问题

```bash
# 检查 SQLite
sqlite3 data/clawnotes.db ".tables"

# 修复
sqlite3 data/clawnotes.db "PRAGMA integrity_check;"
```

---

## 📊 监控

### 添加健康检查

```bash
# 使用 PM2
npm install -g pm2
pm2 start server.js --name clawnotes
pm2 logs
pm2 monit
```

---

## ✅ 部署检查清单

- [ ] 代码已推送到 GitHub
- [ ] 已创建云账户
- [ ] 已配置环境变量
- [ ] 已测试 API 端点
- [ ] 已配置域名 (可选)
- [ ] 已配置 HTTPS (可选)
- [ ] 已配置监控

---

## 📞 支持

如有问题，请提交 Issue: https://github.com/UKplus8HRS/Betternote/issues
