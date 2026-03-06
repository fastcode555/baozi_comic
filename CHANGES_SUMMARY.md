# 图片加载问题修复 - 更改总结

## 修改日期
2026-03-06

## 问题描述
无法在详情页正确获取漫画图片，网页显示"圖片加載失敗了 T_T"。这是因为网站使用了 AMP (Accelerated Mobile Pages) 技术，图片通过 JavaScript 动态加载。

## 修改的文件

### 1. `lib/services/parser_service.dart`

#### 修改内容:
- **增强 `parseChapterImages()` 方法**:
  - 添加多属性检查：`src`, `data-src`, `data-original`, `data-lazy-src`
  - 添加 Script 标签解析：从 JavaScript 代码中提取图片 URL
  - 使用正则表达式在整个 HTML 中搜索 baozicdn.com 的图片 URL

- **增强 `parseChapterImagesWithDimensions()` 方法**:
  - 同样的多属性检查和 Script 标签解析
  - 保留图片尺寸信息

- **添加 `_extractImageCount()` 辅助方法**:
  - 尝试从页面中提取图片数量信息
  - 用于未来可能的图片 URL 构建

### 2. `lib/services/comic_service.dart`

#### 修改内容:
- **增强 `getChapterImages()` 方法**:
  - 添加多域名支持（twmanga.com, baozimh.com, tw.baozimh.com）
  - 添加详细的调试日志
  - 集成 DebugHelper 进行问题诊断
  - 改进错误处理和用户反馈

- **增强 `getChapterDetail()` 方法**:
  - 同样的多域名支持
  - 添加调试日志
  - 改进错误处理

### 3. `lib/utils/debug_helper.dart` (新文件)

#### 功能:
- **`analyzeChapterHtml()`**: 详细分析章节 HTML 结构
  - 检查标题
  - 列出所有 amp-img 标签及其属性
  - 检查 script 标签中的图片数据
  - 使用正则表达式查找图片 URL
  - 检查图片容器元素

- **`saveHtmlToFile()`**: 将 HTML 内容保存到文件
  - 用于离线检查网页结构

- **`testImageUrl()`**: 测试图片 URL 是否可访问
  - 发送 HEAD 请求检查图片可用性

### 4. `test/debug_chapter_images_test.dart` (新文件)

#### 功能:
- 测试获取章节图片功能
- 测试获取章节详情功能
- 输出详细的调试信息
- 测试图片 URL 可访问性

### 5. `DEBUG_IMAGES.md` (新文件)

#### 内容:
- 问题描述和背景
- 已实施的解决方案说明
- 详细的调试步骤
- 常见问题和解决方案
- 下一步建议

### 6. `.github/workflows/build-and-release.yml`

#### 修改内容:
- 更新 Flutter 版本从 3.24.0 到 3.38.6
- 适配包子漫画项目（从 Movie Heaven 项目复制而来）
- 更新所有包名和应用名称
- 更新 DMG 和 ZIP 文件名
- 更新发布说明为中英双语

## 技术细节

### 图片加载策略

1. **优先级 1**: 从 amp-img 标签的多个属性中提取
   ```dart
   String? src = imgElement.attributes['src'] ?? 
                 imgElement.attributes['data-src'] ??
                 imgElement.attributes['data-original'] ??
                 imgElement.attributes['data-lazy-src'];
   ```

2. **优先级 2**: 从 script 标签中提取
   ```dart
   final urlPattern = RegExp(r'https?://[^"\s]+?baozicdn\.com[^"\s]+?\.(?:jpg|jpeg|png|webp|gif)');
   ```

3. **多域名支持**: 按顺序尝试
   - `https://www.twmanga.com`
   - `https://www.baozimh.com`
   - `https://tw.baozimh.com`

### 调试流程

```
用户请求章节图片
    ↓
尝试多个域名获取 HTML
    ↓
解析 HTML (多种方法)
    ↓
如果失败 → 运行 DebugHelper.analyzeChapterHtml()
    ↓
输出详细调试信息
    ↓
返回结果或错误信息
```

## 使用方法

### 运行调试测试
```bash
flutter test test/debug_chapter_images_test.dart
```

### 在应用中查看调试日志
运行应用后，在控制台查看详细的日志输出，包括：
- 尝试的 URL
- HTML 内容长度
- 找到的图片数量
- 详细的 HTML 结构分析

### 保存 HTML 到文件
在 `comic_service.dart` 中取消注释：
```dart
await DebugHelper.saveHtmlToFile(htmlContent, 'chapter_${chapterId}');
```

## 已知限制

1. **JavaScript 依赖**: 如果网站完全依赖 JavaScript 渲染，可能需要使用 WebView 或无头浏览器
2. **反爬虫机制**: 网站可能有反爬虫措施，需要适当的 headers 和延迟
3. **动态 URL**: 图片 URL 可能包含时间戳或签名，需要进一步分析

## 下一步建议

如果当前方案仍无法获取图片：

1. **使用 WebView**: 集成 `webview_flutter` 包，让 JavaScript 执行后再提取图片
2. **API 逆向工程**: 使用浏览器开发者工具找到实际的 API 端点
3. **Puppeteer/Selenium**: 使用无头浏览器渲染页面
4. **代理服务器**: 创建中间服务器处理 JavaScript 渲染

## 测试建议

1. 运行调试测试脚本
2. 检查控制台输出的调试信息
3. 如果需要，保存 HTML 到文件手动检查
4. 在浏览器中对比网页结构
5. 使用开发者工具监控网络请求

## 回滚方案

如果新代码导致问题，可以通过 Git 回滚到之前的版本：
```bash
git checkout HEAD~1 lib/services/parser_service.dart
git checkout HEAD~1 lib/services/comic_service.dart
```
