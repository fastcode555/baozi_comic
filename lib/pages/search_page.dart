import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/search_controller.dart' as comic_search;
import '../widgets/comic_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/error_widget.dart';

class SearchPage extends GetView<comic_search.SearchController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildSearchField(),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios),
          onPressed: () => Get.back(),
        ),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const LoadingWidget();
        }

        if (controller.error.isNotEmpty) {
          return CustomErrorWidget(
            error: controller.error,
            onRetry: () => controller.retry(),
          );
        }

        return Column(
          children: [
            // 搜索建议
                if (controller.hasSuggestions) _buildSuggestions(),
            
            // 搜索结果或历史记录
            Expanded(
              child: controller.hasResults
                  ? _buildSearchResults()
                  : _buildSearchHistory(),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildSearchField() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: TextField(
        controller: controller.searchTextController,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          hintText: '搜索漫画名、作者名',
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          suffixIcon: Icon(Icons.search, size: 20),
        ),
                onChanged: controller.getSuggestions,
        onSubmitted: controller.searchComics,
      ),
    );
  }

  Widget _buildSuggestions() {
    return Container(
      constraints: const BoxConstraints(maxHeight: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: ListView.builder(
        shrinkWrap: true,
        itemCount: controller.suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = controller.suggestions[index];
          return ListTile(
            dense: true,
            leading: const Icon(Icons.search, size: 20),
            title: Text(suggestion),
                onTap: () => controller.selectSuggestion(suggestion),
          );
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    return Column(
      children: [
        // 搜索结果标题
        Container(
          padding: const EdgeInsets.all(16),
          alignment: Alignment.centerLeft,
          child: Text(
            '搜索结果 (${controller.searchResults.length})',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        
        // 搜索结果列表
        Expanded(
          child: controller.searchResults.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '没有找到相关漫画',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 285 / (375 + 100), // 约等于 0.67
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: controller.searchResults.length,
                  itemBuilder: (context, index) {
                    final comic = controller.searchResults[index];
                    return ComicCard(
                      comic: comic,
                      onTap: () => Get.toNamed('/comic/${comic.id}', arguments: comic),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildSearchHistory() {
    return Column(
      children: [
        // 搜索历史标题
        if (controller.searchHistory.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  '搜索历史',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: controller.clearSearchHistory,
                  child: const Text('清空'),
                ),
              ],
            ),
          ),
        
        // 搜索历史列表
        Expanded(
          child: controller.searchHistory.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.history,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        '暂无搜索历史',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: controller.searchHistory.length,
                  itemBuilder: (context, index) {
                    final query = controller.searchHistory[index];
                    return ListTile(
                      leading: const Icon(Icons.history),
                      title: Text(query),
                      trailing: IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => controller.removeSearchHistoryItem(query),
                      ),
                      onTap: () => controller.selectHistory(query),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
