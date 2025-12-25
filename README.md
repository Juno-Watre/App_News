# Personal News Brief

一个基于Flutter开发的个人新闻简报应用，支持RSS订阅、AI摘要和外部笔记集成。

## 功能特性

- 📰 RSS订阅管理：支持RSS 2.0和Atom格式
- 🤖 AI摘要：集成OpenAI/Claude API生成文章摘要，支持本地降级方案
- 📝 外部编辑器联动：支持Joplin、Markor等外部编辑器的深度链接调用
- 📝 笔记集成：支持Joplin、Obsidian等外部笔记工具
- 🌟 文章收藏：收藏重要文章便于后续查看
- 🔍 全文搜索：支持标题、内容和摘要的全文搜索
- 📱 Material 3设计：现代化的用户界面，支持系统主题切换
- 🔄 自动同步：定期更新RSS订阅源
- 📱 原生交互：Android原生功能支持

## 技术栈

- **前端框架**: Flutter (Dart 3.x)
- **状态管理**: Riverpod
- **本地数据库**: Isar (支持全文检索)
- **网络请求**: Dio
- **UI组件**: Material 3 (Adaptive), flutter_html
- **原生交互**: Kotlin (Android)
- **外部集成**: share_plus, url_launcher

## 项目结构

```
lib/
├── app/                          # 应用入口
│   └── app.dart
├── core/                         # 核心功能
│   ├── database/                 # 数据库服务
│   │   └── isar_service.dart
│   └── platform/                 # 平台交互
│       └── platform_service.dart
├── features/                     # 功能模块
│   ├── article/                  # 文章相关
│   │   ├── data/
│   │   │   └── models/
│   │   │       └── article.dart  # 文章数据模型
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── article_provider.dart  # 状态管理
│   │       └── pages/
│   │           └── article_list_page.dart  # 文章列表页
│   ├── home/                     # 主页
│   │   └── presentation/
│   │       └── pages/
│   │           └── home_page.dart
│   ├── rss/                      # RSS订阅
│   │   ├── data/
│   │   │   └── services/
│   │   │       └── rss_parser_service.dart  # RSS解析服务
│   │   └── presentation/
│   │       └── pages/
│   │           └── rss_sources_page.dart     # RSS源管理页
│   ├── summary/                  # AI摘要
│   │   └── data/
│   │       └── services/
│   │           └── ai_summary_service.dart   # AI摘要服务
│   └── note/                     # 笔记集成
│       └── data/
│           └── services/
│               └── note_service.dart         # 笔记服务
└── main.dart                     # 应用入口点
```

## 数据模型

### Article

```dart
class Article {
  final Id id;                    // Isar数据库ID
  final String title;             // 文章标题
  final String content;           // 文章内容(HTML/Markdown)
  final String url;               // 文章链接(唯一索引)
  final String source;            // 文章来源
  final DateTime publishedAt;     // 发布时间
  final bool isStar;              // 是否收藏
  final bool isRead;              // 是否已读
  final String? summary;          // AI摘要
  final String? noteExternalId;   // 外部笔记ID
}
```

## 核心服务

### RSS解析服务

支持RSS 2.0和Atom格式的解析，自动处理网络异常和解析异常。

```dart
class RssParserService {
  Future<List<Article>> parseFeed(String url) async {
    // 解析RSS/Atom订阅源
    // 处理网络异常和解析异常
    // 返回文章列表
  }
}
```

### AI摘要服务

支持多种AI服务提供商：

```dart
// OpenAI摘要服务
OpenAiSummaryService(apiKey: 'your-api-key');

// Claude摘要服务
ClaudeSummaryService(apiKey: 'your-api-key');

// 本地摘要服务
LocalSummaryService();
```

### 笔记集成服务

支持多种笔记工具：

```dart
// Joplin笔记服务
JoplinNoteService(token: 'your-token');

// Obsidian笔记服务
ObsidianNoteService(vaultPath: '/path/to/vault');
```

## Android原生功能

### 平台服务

提供以下原生功能：

- URL打开
- 文本分享
- 通知管理
- 快捷方式创建
- 设备信息获取
- 网络状态检查

### 权限配置

应用需要以下权限：

```xml
<!-- 网络权限 -->
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />

<!-- 通知权限 (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />

<!-- 安装快捷方式权限 -->
<uses-permission android:name="android.permission.INSTALL_SHORTCUT" />
```

## 使用方法

### 添加RSS订阅源

1. 点击首页右下角的"+"按钮
2. 输入订阅源名称和URL
3. 点击"添加"按钮

### 生成AI摘要

1. 打开文章详情页
2. 点击"生成摘要"按钮
3. 等待摘要生成完成

### 创建外部笔记

1. 打开文章详情页
2. 点击"创建笔记"按钮
3. 笔记将自动保存到配置的外部笔记工具

### 搜索文章

1. 点击首页顶部的搜索图标
2. 输入搜索关键词
3. 查看搜索结果

## 配置

### AI摘要服务

在应用中配置AI服务：

```dart
final summaryService = SummaryServiceFactory.createService('openai', {
  'apiKey': 'your-openai-api-key',
});
```

### 笔记服务

配置笔记服务：

```dart
final noteService = NoteServiceFactory.createService('joplin', {
  'token': 'your-joplin-token',
  'baseUrl': 'http://localhost:41184',
});
```

## 开发环境设置

1. 克隆项目
2. 安装依赖：`flutter pub get`
3. 运行代码生成：`flutter packages pub run build_runner build`
4. 运行应用：`flutter run`

## 依赖包

- `flutter_riverpod`: 状态管理
- `isar`: 本地数据库
- `dio`: 网络请求
- `xml`: XML解析
- `path_provider`: 路径获取
- `intl`: 国际化
- `material_color_utilities`: Material 3颜色工具

## 许可证

MIT License

## 贡献

欢迎提交Issue和Pull Request！