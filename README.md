# DeepSeek客户端

> 一款 iOS 原生通用 AI 大模型对话客户端，解决「在手机上调用大模型 API 不方便」的问题。只需填入一个兼容 OpenAI Chat Completions 格式的接口地址、模型名与 API Key，即可在 iPhone 上进行原生流式对话。
>
> 支持 iOS 15 及以上，iOS 26 下采用 Apple 原生 Liquid Glass 液态玻璃，跟随系统深色/浅色模式。密钥仅存本机钥匙串，应用不内置任何账号体系，不捆绑任何服务商。
>
> 作者：**TiantianYe**
>
> 作者在 App Store 中的其他代表作品：水课帮-课堂提问助手；识词本-单词笔记；投影与视图3D教具；实验数据拟合；解构照片。

---

## ✨ 这是什么

`DeepSeek客户端` 是一个用 Swift / SwiftUI 写的 iOS 开源客户端。它本身不提供模型，而是一个**通用的 API 对话壳**：

- 官方 App 功能固定、网页端操作繁琐，而开发者手里的 API Key 缺少一个干净、原生的移动端入口；
- 本项目把「填接口 → 流式对话 → 历史管理 → 多模态附件」做成本地 App，任意兼容 OpenAI Chat Completions 格式的服务（官方接口、聚合平台、自建服务）都能接入；
- **不内置任何 API Key**，也不上传任何配置到第三方服务器。所有密钥只存在 iOS Keychain，对话记录只存在 App 沙盒。

核心能力：

- 流式逐字回复，深度思考内容以可折叠区域展示；
- 深度思考 / 智能搜索双开关（分别切换思考模型、附加联网搜索参数）；
- 拍照 / 相册 / 最近照片 / 文件四种附件，图片以标准 `image_url` 多模态格式发送；
- 历史会话本地持久化，支持搜索、重命名、删除；
- iOS 26 原生 Liquid Glass 液态玻璃按钮与融合动效，低版本自动回退系统材质。

## 🎯 使用场景

| 要素 | 说明 |
|---|---|
| 使用者 | 有大模型 API Key、希望在 iPhone 上便捷调用的开发者或进阶用户 |
| 接口要求 | 兼容 OpenAI Chat Completions：`POST {Base URL}/chat/completions`，Bearer 鉴权，SSE 流式 |
| 典型服务 | DeepSeek 官方接口、各类兼容聚合平台、自建 OpenAI 兼容网关 |
| 典型诉求 | "手机上有 Key 但没好用的客户端"、"想要原生液态玻璃的对话界面"、"想给模型发图片/文件" |

## 📦 安装

```bash
git clone https://github.com/TiantianYeTTY/DeepSeek客户端.git
cd DeepSeek客户端
xcodegen generate --spec project.yml --project .
open DeepSeekClient.xcodeproj
```

在 Xcode 中选择 `DeepSeekClient` target 与模拟器/真机，直接 Run 即可。

> 需要 [xcodegen](https://github.com/yonaskolb/XcodeGen)（`brew install xcodegen`）。工程由 `project.yml` 生成，**不要手改 `project.pbxproj`**；改配置后重新执行 `xcodegen generate`。

## 🚀 使用方法

1. 打开 App，点击左上角菜单按钮查看历史对话；点击右上角胶囊中的「+」新建会话。
2. 首次使用先配置接口：左上角菜单 → 底部「…」→「账号管理」。
3. 填写：
   - **Base URL**：接口根地址（如 `https://api.deepseek.com` 或带 `/v1` 的路径，末尾不要斜杠）。
   - **对话模型** / **深度思考模型**：所用服务支持的模型名。
   - **API Key**：仅存本机钥匙串，不会写入源码或上传。
4. 点右上角「完成」自动保存。
5. 回到对话页输入内容，点「↑」发送；按需开启「深度思考」「智能搜索」。
6. 点输入框右侧「⊕」展开附件区：最近照片 / 拍照 / 相册 / 文件，再点变「⊗」收起。
7. 点击输入框以外区域可收起键盘。

## 🔧 环境依赖

- **Xcode 26+**（本项目在 Xcode 27.2 / Swift 6.4.2 下开发；工程使用 Swift 5 语言模式）。
- **iOS 15.0+** 部署目标；iOS 26+ 才呈现 Liquid Glass，低版本回退系统材质。
- **xcodegen 2.46+**：`brew install xcodegen`。
- 命令行构建需带 `OTHER_SWIFT_FLAGS="-disable-sandbox"`（已写入 `project.yml`），否则 SwiftUI 宏插件在某些环境编译失败；Xcode GUI 构建不受影响。
- 相册/相机/文件附件使用系统原生 `PHPickerViewController` / `UIImagePickerController` / `UIDocumentPickerViewController`，Info.plist 已含用途说明。

## ⚠️ 重要说明

1. **不内置任何 API Key**：请自行在 App 内填写。仓库中不含、也不应提交任何密钥。
2. **接口兼容性**：`web_search` 参数仅在服务商支持时有效；部分官方接口可能忽略或拒绝该字段，关闭「智能搜索」即可。
3. **图片发送需要模型支持视觉理解**：图片以 `data:image/jpeg;base64,...` 的 `image_url` 格式发送，纯文本模型会报错，属模型能力边界。
4. **外观跟随系统**：App 不提供深浅色手动切换。
5. **本地存储**：对话记录保存在 App 沙盒 `Documents/conversations.json`，卸载 App 即清除。

## 📁 目录结构

```
DeepSeek客户端/
├── README.md                  ← 本文件
├── LICENSE                    ← CC BY-SA 4.0
├── 项目交接文档.md             ← 开发记录与交接约定（可追加）
├── APP描述.md                 ← App 简介/功能/用法
├── project.yml                ← xcodegen 工程唯一配置源
├── icon.icon/                 ← App 图标（Icon Composer 格式，iOS 26 液态玻璃图标）
├── DeepSeekClient/
│   ├── DeepSeekClientApp.swift       # 入口（外观跟随系统）
│   ├── ContentView.swift             # 根容器：聊天页 + 侧边栏 + 设置 sheet
│   ├── Models/
│   │   ├── ChatModels.swift          # ChatMessage / Conversation
│   │   ├── AppPreferences.swift      # 接口配置持久化 + Keychain 读取
│   │   └── ConversationStore.swift   # 会话本地持久化
│   ├── Services/
│   │   ├── ChatService.swift         # 流式请求 / SSE 解析 / 请求体构建（纯函数可测）
│   │   └── Keychain.swift            # 密钥安全存储
│   └── Views/
│       ├── GlassComponents.swift     # 原生 Liquid Glass 兼容层 + 圆形玻璃按钮
│       ├── ChatView.swift            # 对话首页与输入区
│       ├── MessageBubble.swift       # 消息气泡 + 可折叠深度思考
│       ├── SidebarView.swift         # 历史对话抽屉 + 原生搜索框
│       ├── SettingsView.swift        # 账号管理 / 数据管理
│       ├── AttachmentPickers.swift   # 相册/相机/文件选择器
│       └── RecentPhotosStrip.swift   # 最近照片条
├── DeepSeekClientTests/       # 单元测试（流式修剪 / 开关请求体 / 多模态）
├── DeepSeekClientUITests/     # UI 测试（界面 / chip / 附件展开 / 键盘收起）
└── Screenshots/               # 界面截图
```

## 🛠️ 测试

```bash
xcodebuild test \
  -project DeepSeekClient.xcodeproj \
  -scheme DeepSeekClient \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -derivedDataPath .build \
  CODE_SIGNING_ALLOWED=NO \
  OTHER_SWIFT_FLAGS="-disable-sandbox"
```

单元测试自包含（不依赖外部服务）；UI 测试覆盖 chip 切换、附件展开/收起、点击空白收起键盘。

## 🐛 已知踩坑点（节选）

- **按钮语义**（按设计图定稿，勿改错）：右上角胶囊 = 静音 + 新建会话；输入框右侧「⊕」= 展开附件，「↑」= 发送；发送图标用普通 `arrow.up`，**不要**用 `arrow.up.circle.fill`（会与圆形玻璃按钮形成套娃），本 App 无语音识别功能，不要用声波图标。
- **Liquid Glass**：iOS 26+ 用 `.buttonStyle(.glass)` / `.glassProminent` 与 `.glassEffect(.regular.interactive())`；`.circle` 按钮轮廓仅 iOS 17+，低版本用 `.capsule` + `clipShape`。
- **搜索框**：SwiftUI `.searchable` 在 iOS 26 `NavigationView` inline 模式下会把搜索框排到列表底部，本项目改用 `UISearchBar` 包装（`NativeSearchBar`），位置可控且自动液态玻璃。
- **前导空行**：部分服务商把流式正文首块发成 `"\n\n"`，`trimmedStreamChunk` 在正式文字出现前跳过纯空白块。
- **命令行编译**：SwiftUI 宏插件需要 `-disable-sandbox`，否则 `swift-plugin-server` 报 malformed response。
- **键盘收起**：在根视图加 `.contentShape(Rectangle()).onTapGesture { resignFirstResponder }`，不要只加在 `background` 上。
- **测试目标类型**（xcodegen 2.46）：UI 测试 `bundle.ui-testing`，单元测试 `bundle.unit-test`。

## 👤 作者

**TiantianYe**

作者在 App Store 中的其他代表作品：水课帮-课堂提问助手；识词本-单词笔记；投影与视图3D教具；实验数据拟合；解构照片。

欢迎通过 Issue 反馈问题，或提交 PR 完善功能。

## 📄 许可

本项目采用 [Creative Commons Attribution-ShareAlike 4.0 International](LICENSE)（CC BY-SA 4.0）许可，仅供学习交流使用。
