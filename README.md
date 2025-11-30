# ZiChat

一款仿微信界面的 AI 聊天应用，支持自定义 AI 好友和个性化对话。

## 功能特性

### 🤖 AI 聊天
- **多模型支持**: 支持 Kimi、Qwen、GLM、DeepSeek 等多种 AI 模型
- **AI 生图**: 支持通过 ModelScope 生成图片
- **独立上下文**: 每个好友独立的对话历史和上下文
- **工具调用**: AI 可调用图片生成、转账、表情等工具

### 👥 好友系统
- **自定义好友**: 创建 AI 好友，设置头像和人设
- **个性化提示词**: 每个好友可设置独立的人设提示词
- **聊天记录**: 独立存储每个好友的聊天记录

### 💬 聊天功能
- **消息搜索**: 支持搜索聊天记录
- **图片消息**: 发送图片、AI 生成图片
- **转账消息**: 模拟微信转账功能
- **聊天背景**: 自定义聊天页背景（纯色/图片）
- **图片保存**: 长按图片保存到本地
- **分页加载**: 聊天记录分页加载，优化性能
- **主动消息**: AI 会根据时间、情绪等主动发消息

### ⚙️ 设置
- **模型选择**: 在设置中切换 AI 模型
- **API 配置**: 支持自定义 API 接口

## 技术栈

- **Flutter** - 跨平台框架
- **Hive** - 本地数据存储
- **HTTP** - API 通信

## 项目结构

```
lib/
├── config/          # 配置文件
│   ├── ai_models.dart      # AI 模型配置
│   └── api_secrets.dart    # API 密钥
├── constants/       # 常量定义
│   ├── app_colors.dart     # 颜色常量
│   └── app_styles.dart     # 样式常量
├── models/          # 数据模型
│   ├── chat_message.dart   # 聊天消息模型
│   └── friend.dart         # 好友模型
├── pages/           # 页面
│   ├── chat_detail/        # 聊天详情页
│   ├── chats_page.dart     # 聊天列表页
│   ├── contacts_page.dart  # 通讯录页
│   └── ...
├── services/        # 服务层
│   ├── ai_chat_service.dart    # AI 聊天服务
│   ├── ai_tools_service.dart   # AI 工具服务
│   ├── image_gen_service.dart  # 图片生成服务
│   └── ...
├── storage/         # 存储层
│   ├── chat_storage.dart       # 聊天存储
│   ├── friend_storage.dart     # 好友存储
│   └── ...
└── main.dart        # 应用入口
```

## 开始使用

### 环境要求
- Flutter SDK >= 3.10.0
- Dart SDK >= 3.0.0

### 安装依赖
```bash
flutter pub get
```

### 运行应用
```bash
flutter run
```

### 构建 APK
```bash
flutter build apk --release --target-platform android-arm64
```

## API 配置

应用内置了 API 配置，也支持自定义配置：

1. 打开 "我" -> "设置" -> "通用" -> "AI 配置"
2. 填写 API 地址、密钥和模型名称

### 支持的 API
- **iFlow**: https://apis.iflow.cn/v1
- **ModelScope**: https://api-inference.modelscope.cn/v1 (图片生成)

## 开发说明

### AI 提示词
系统提示词位于 `sprompt.md`，可自定义 AI 的基础人设。

### 工具调用格式
AI 可使用以下工具：
```
<tool>image_gen(prompt)</tool>  - 生成图片
<tool>transfer(amount)</tool>   - 发送转账
<tool>emoji(name)</tool>        - 发送表情
```

### 消息分句
AI 回复中使用 `\` 分隔多条消息：
```
好啊\什么时候  -> 显示为两条消息
```

## GitHub Actions

项目配置了自动构建：
- 推送到 main 分支自动触发 Android APK 构建
- 构建产物可在 Actions 中下载

## 许可证

MIT License
