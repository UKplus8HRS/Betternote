# ClawNotes (BetterNotes)

一个类似 GoodNotes 的 iPad 手写笔记应用，支持 Apple Pencil 和 iCloud 同步。

## 功能特点

- ✍️ **手写笔记** - 使用 Apple Pencil，支持压感和倾斜感应
- 📓 **笔记本管理** - 创建、编辑、删除笔记本
- 📄 **页面管理** - 添加、删除、重新排序页面
- 🎨 **丰富工具** - 钢笔、荧光笔、橡皮擦、颜色选择
- ↩️ **撤销/重做** - 支持多步撤销
- ☁️ **iCloud 同步** - 多设备同步 (使用 CloudKit)
- 🔄 **后端 API** - 支持自建后端服务

## 技术栈

### 前端 (iPad App)
- **SwiftUI** - UI 框架
- **PencilKit** - 手写引擎
- **CloudKit** - iCloud 同步

### 后端 (可选)
- **Node.js** + **Express** - API 服务
- **SQLite** - 数据存储

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
├── CloudKit/                 # iCloud 同步
│   └── CloudKitManager.swift
├── Resources/                # 资源文件
│   └── Assets.xcassets/
└── backend/                  # 后端 API (可选)
    ├── server.js
    ├── routes/
    │   ├── notebooks.js
    │   └── pages.js
    └── models/
        └── database.js
```

## 快速开始

### 前端 (iPad App)

1. **环境要求**
   - macOS (运行 Xcode)
   - Xcode 14+
   - Apple Developer 账号 (免费即可)

2. **打开项目**
   ```bash
   # 克隆仓库后
   cd ClawNotes
   open ClawNotes.xcodeproj
   ```

3. **配置**
   - 在 Xcode 中选择你的开发团队
   - 修改 Bundle Identifier
   - 启用 iCloud 能力 (CloudKit)

4. **运行**
   - 连接 iPad 或使用模拟器
   - 按 Cmd+R 运行

### 后端 (可选)

1. **安装依赖**
   ```bash
   cd backend
   npm install
   ```

2. **启动服务**
   ```bash
   npm start
   ```

3. **API 端点**
   - `GET /api/notebooks` - 获取所有笔记本
   - `POST /api/notebooks` - 创建笔记本
   - `GET /api/notebooks/:id` - 获取笔记本详情
   - `PUT /api/notebooks/:id` - 更新笔记本
   - `DELETE /api/notebooks/:id` - 删除笔记本
   - `GET /api/pages/:notebookId` - 获取所有页面
   - `PUT /api/pages/page/:id` - 更新页面绘图数据

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
