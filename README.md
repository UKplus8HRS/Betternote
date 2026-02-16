# ClawNotes (BetterNotes)

一个类似 GoodNotes 的 iPad 手写笔记应用，支持 Apple Pencil、多语言和云同步。

![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0+-orange.svg)
![Platform](https://img.shields.io/badge/Platform-iPad-blue.svg)
![License](https://img.shields.io/badge/License-MIT-green.svg)

## 📱 功能特点

### 核心功能
- ✍️ **手写笔记** - 使用 Apple Pencil，支持压感和倾斜感应
- 📓 **笔记本管理** - 创建、编辑、删除、重命名笔记本
- 📄 **页面管理** - 添加、删除、重新排序页面
- 🎨 **丰富工具** - 钢笔、荧光笔、马克笔、铅笔、橡皮擦
- ↩️ **撤销/重做** - 支持多步撤销
- 📱 **标签页** - 支持多标签页同时打开
- 📱 **分屏模式** - iPad 分屏多任务支持
- 🪟 **多窗口** - 同一应用内新建窗口

### 模板
- 空白页面
- 横线
- 网格
- 点阵
- 待办清单
- 日历

### 手势
- 双指缩放
- 双指旋转
- 双击重置视图
- 手掌防误触

### 导入/导出
- 📄 **PDF 导出** - 高质量 PDF 导出
- 📄 **PDF 导入** - 从 PDF 导入页面
- 🖼️ **图片导出**
- 📝 **Markdown 导出**
- 📝 **纯文本导出**

### 云同步
- ☁️ **iCloud (CloudKit)** - 多设备同步
- 🔄 **离线支持** - 本地缓存 + 在线同步
- ⚔️ **冲突解决** - 自动合并冲突

### AI 功能
- 🎙️ **语音转文字** - 实时语音识别
- ✍️ **手写识别** - Vision 框架文字识别
- 📐 **数学公式识别** - 手写数学公式转 LaTeX
- 🔷 **图形识别** - 自动识别矩形、圆形、线条
- 🤖 **AI 助手** - 润色、翻译、摘要、扩展
- 🎙️ **AI 录音总结** - 录音自动生成摘要和要点

### 协作
- 🔗 **分享链接** - 生成分享链接
- 👥 **协作者管理** - 添加/移除协作者
- 🔐 **权限控制** - 查看者/编辑者/所有者

### 安全
- 🔒 **Face ID / Touch ID** - 生物识别解锁
- 🔑 **应用密码** - 密码保护
- ⏰ **自动锁定** - 离开自动锁定
- 🔐 **数据加密** - 本地数据加密

### 主题
- 🎨 **预设主题** - 默认/夜间/柔和/经典
- ✨ **自定义主题** - 创建自己的主题

### 更多
- 🏷️ **文件夹管理** - 用文件夹整理笔记本
- 🔍 **搜索** - 搜索笔记本和页面
- 📦 **贴纸** - Emoji 贴纸库
- 💾 **备份与恢复** - 完整数据备份
- 🎬 **演示模式** - 幻灯片演示
- 🌍 **多语言** - 支持 8 种语言
- ⌚ **Widget** - iOS 小组件

## 🌍 多语言

- 🇺🇸 English
- 🇨🇳 简体中文
- 🇭🇰 繁體中文
- 🇯🇵 日本語
- 🇰🇷 한국어
- 🇪🇸 Español
- 🇫🇷 Français
- 🇩🇪 Deutsch

## 🛠️ 技术栈

### 前端
- **SwiftUI** - UI 框架
- **PencilKit** - 手写引擎
- **CloudKit** - iCloud 同步
- **Vision** - AI 识别
- **Speech** - 语音识别
- **WidgetKit** - 小组件

### 后端 (可选)
- **Node.js** + **Express** - API 服务
- **SQLite** - 数据存储
- **Firebase Auth** - 用户认证

## 📂 项目结构

```
ClawNotes/
├── App/                      # App 入口
├── Models/                   # 数据模型
├── Views/                    # 视图
├── ViewModels/               # 业务逻辑
├── CloudKit/                 # iCloud + 认证
├── AI/                      # AI 功能
├── Localization/            # 多语言
├── Settings/                # 设置
├── Themes/                  # 主题
├── Security/                # 安全
├── Collaboration/           # 协作
├── Export/                 # 导出
├── Import/                 # 导入
├── Stickers/               # 贴纸
├── Backup/                 # 备份
├── Presentation/            # 演示
├── PencilKit/              # 画笔预设
├── Widgets/                # 小组件
└── backend/                # 后端 API
```

## 🚀 快速开始

### 前端

1. 克隆项目
```bash
git clone https://github.com/UKplus8HRS/Betternote.git
```

2. 用 Xcode 打开
```bash
cd ClawNotes
open ClawNotes.xcodeproj
```

3. 配置
- 选择开发团队
- 修改 Bundle Identifier
- 启用 iCloud 能力 (CloudKit)
- 添加 Firebase 配置 (可选)

4. 运行
- 连接 iPad 或使用模拟器
- 按 Cmd+R 运行

### 后端 (可选)

```bash
cd backend
npm install
npm start
```

## 📋 版本历史

| 版本 | 内容 |
|------|------|
| v1.0 | 基础框架 |
| v1.1 | 页面模板 + 工具栏 |
| v1.2 | 手势操作 |
| v1.3 | PDF 导入/导出 |
| v1.4 | 文件夹 + 搜索 |
| v1.5 | 离线支持 |
| v2.0 | AI 功能 |
| v2.1 | Widget 小组件 |
| v2.2 | 协作分享 |
| v2.3 | 增强导出 |
| v2.4 | 安全功能 |
| v2.5 | 主题系统 |
| v2.6 | Apple Watch (已移除) |
| v2.7 | 贴纸系统 |
| v2.8 | 备份恢复 |
| v2.9 | 演示模式 |
| v3.0 | 标签页 + 分屏 |
| v3.1 | 多语言支持 |
| v3.2 | AI 录音总结 |

## 📄 许可证

MIT License

---

Made with ❤️
