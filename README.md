# ClawNotes (BetterNotes)

一个类似 GoodNotes 的 iPad 手写笔记应用，支持 Apple Pencil 和多平台登录。

## 功能特点

- ✍️ **手写笔记** - 使用 Apple Pencil，支持压感和倾斜感应
- 📓 **笔记本管理** - 创建、编辑、删除笔记本
- 📄 **页面管理** - 添加、删除、重新排序页面
- 🎨 **丰富工具** - 钢笔、荧光笔、橡皮擦、颜色选择
- ↩️ **撤销/重做** - 支持多步撤销
- ☁️ **iCloud 同步** - 多设备同步 (使用 CloudKit)
- 👤 **多平台登录** - Apple / Google / WeChat / Email / 匿名

## 技术栈

### 前端 (iPad App)
- **SwiftUI** - UI 框架
- **PencilKit** - 手写引擎
- **CloudKit** - iCloud 同步
- **Firebase Auth** - 用户认证

### 后端 (可选)
- **Node.js** + **Express** - API 服务
- **SQLite** - 数据存储
- **Firebase Admin** - Token 验证

## 项目结构

```
ClawNotes/
├── App/                      # SwiftUI App 入口
│   ├── ClawNotesApp.swift
│   └── ContentView.swift
├── Models/                   # 数据模型
│   ├── Notebook.swift
│   └── NotePage.swift
├── Views/                    # 视图
│   ├── NotebookListView.swift
│   ├── NotebookDetailView.swift
│   ├── NoteCanvasView.swift
│   └── Components/
│       └── NotebookCoverView.swift
├── ViewModels/               # 业务逻辑
│   └── NotebookViewModel.swift
├── CloudKit/                 # iCloud + 认证
│   ├── CloudKitManager.swift
│   ├── FirebaseConfig.swift
│   └── AuthManager.swift
├── Resources/                # 资源文件
│   └── Assets.xcassets/
└── backend/                  # 后端 API
    ├── server.js
    ├── routes/
    │   ├── notebooks.js
    │   ├── pages.js
    │   └── users.js
    └── middleware/
        ├── auth.js
        └── firebase.js
```

## 快速开始

### 1. Firebase 配置

#### 创建 Firebase 项目
1. 访问 [Firebase Console](https://console.firebase.google.com)
2. 创建新项目
3. 添加 iOS 应用

#### 启用登录方式
在 Firebase Console → Authentication → 登录方式：
- ✅ Apple
- ✅ Google
- ✅ WeChat (需要微信开放平台)
- ✅ Email/密码
- ✅ 匿名

#### 下载配置
1. 下载 `GoogleService-Info.plist` (iOS)
2. 下载服务账号密钥 `serviceAccountKey.json` (后端)

### 2. 前端 (iPad App)

```bash
# 克隆仓库后
cd ClawNotes
open ClawNotes.xcodeproj
```

**Xcode 配置：**
1. 选择你的开发团队
2. 修改 Bundle Identifier
3. 启用 iCloud 能力 (CloudKit)
4. 添加 `GoogleService-Info.plist`
5. 配置 URL Schemes (用于 Google/WeChat 登录)

### 3. 后端 (可选)

```bash
cd backend

# 安装依赖
npm install

# 配置 Firebase
# 将 serviceAccountKey.json 重命名为 firebase-service-account.json

# 启动服务
npm start
```

## 登录方式配置

### Apple 登录
- 需要 Apple Developer 账号
- 在 Xcode → Signing & Capabilities → Capabilities → Sign in with Apple

### Google 登录
- 在 Firebase Console 启用 Google 登录
- 在 Xcode 配置 URL Schemes: `com.googleusercontent.apps.YOUR_CLIENT_ID`

### WeChat 登录
- 需要[微信开放平台](https://open.weixin.qq.com)账号
- 在微信开放平台创建应用
- 在 Firebase Console 配置 App ID 和 Secret

## API 端点

### 笔记本
- `GET /api/notebooks` - 获取所有笔记本
- `POST /api/notebooks` - 创建笔记本
- `GET /api/notebooks/:id` - 获取笔记本详情
- `PUT /api/notebooks/:id` - 更新笔记本
- `DELETE /api/notebooks/:id` - 删除笔记本

### 页面
- `GET /api/pages/:notebookId` - 获取所有页面
- `POST /api/pages` - 创建页面
- `PUT /api/pages/page/:id` - 更新页面绘图数据

### 用户
- `GET /api/users/me` - 获取当前用户信息
- `POST /api/users/anon` - 创建匿名用户

## 界面预览

参考 GoodNotes 风格：
- 网格布局的笔记本列表
- 封面颜色选择
- 底部悬浮工具栏
- 页面缩略图导航

## 未来计划

- [ ] PDF 导出
- [ ] 笔记模板
- [ ] 桌面客户端 (Electron)
- [ ] 跨平台同步

## 许可证

MIT License
