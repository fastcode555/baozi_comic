# 图片加载问题调试指南

## 问题描述

在详情页无法正确获取漫画图片，可能是因为网站使用了 JavaScript 动态加载图片（AMP 技术）。

## 已实施的解决方案

### 1. 增强的图片解析逻辑

更新了 `lib/services/parser_service.dart` 中的图片解析方法：

- **多属性检查**: 现在会检查 `src`, `data-src`, `data-original`, `data-lazy-src` 等多个属性
- **Script 标签解析**: 如果 amp-img 标签中没有图片，会尝试从 JavaScript 代码中提取图片 URL
- **正则表达式匹配**: 使用正则表达式在整个 HTML 中搜索 baozicdn.com 的图片 URL

### 2. 多域名支持

更新了 `lib/services/comic_service.dart` 来尝试多个可能的域名：

- `https://www.twmanga.com`
- `https://www.baozimh.com`
- `https://tw.baozimh.com`

### 3. 调试工具

创建了 `lib/utils/debug_helper.dart` 提供以下功能：

- **HTML 分析**: 详细分析章节 HTML 结构
- **图片 URL 测试**: 测试图片 URL 是否可访问
- **HTML 保存**: 将 HTML 内容保存到文件以便检查

## 如何调试

### 方法 1: 运行测试脚本

```bash
flutter test test/debug_chapter_images_test.dart
```

这将：
1. 尝试获取第246话的图片
2. 输出详细的调试信息
3. 测试图片 URL 是否可访问

### 方法 2: 在应用中启用调试

在 `lib/services/comic_service.dart` 中，取消注释以下行：

```dart
// await DebugHelper.saveHtmlToFile(htmlContent, 'chapter_${chapterId}');
```

这将把 HTML 内容保存到文件，你可以手动检查网页结构。

### 方法 3: 手动检查网页

1. 在浏览器中打开章节页面
2. 右键点击 -> 检查元素
3. 查看 `amp-img` 标签的属性
4. 检查是否有 `<script>` 标签包含图片数据

## 可能的问题和解决方案

### 问题 1: 网站使用 JavaScript 动态加载

**症状**: HTML 中只有占位符，没有实际图片 URL

**解决方案**:
- 使用 Selenium 或 Puppeteer 等工具模拟浏览器
- 或者找到网站的 API 端点直接获取图片列表

### 问题 2: 图片需要特殊的 Headers 或 Cookies

**症状**: 图片 URL 存在但无法访问

**解决方案**:
- 在 `lib/services/http_service.dart` 中添加必要的 headers
- 可能需要先访问漫画详情页获取 cookies

### 问题 3: 图片 URL 模式已更改

**症状**: 旧的 URL 模式不再有效

**解决方案**:
- 使用调试工具分析新的 HTML 结构
- 更新 `parser_service.dart` 中的解析逻辑

## 下一步

如果以上方法都无法解决问题，可以考虑：

1. **使用 WebView**: 在 Flutter 中嵌入 WebView 加载章节页面，让 JavaScript 执行后再提取图片
2. **反向工程 API**: 使用浏览器开发者工具监控网络请求，找到实际的图片数据 API
3. **使用代理服务器**: 创建一个中间服务器来处理 JavaScript 渲染

## 联系和反馈

如果你发现了新的解决方案或遇到其他问题，请更新此文档。
