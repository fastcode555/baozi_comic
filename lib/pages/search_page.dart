import 'package:baozi_comic/controllers/search_controller.dart' as comic_search;
import 'package:baozi_comic/widgets/comic_card.dart';
import 'package:baozi_comic/widgets/error_widget.dart';
import 'package:baozi_comic/widgets/loading_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tailwind/flutter_tailwind.dart';
import 'package:get/get.dart';

class SearchPage extends GetView<comic_search.SearchController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _buildSearchField(),
        leading: const Icon(Icons.arrow_back_ios).iconClick(onTap: Get.back),
      ),
      body: Obx(() {
        if (controller.isLoading) {
          return const LoadingWidget();
        }

        if (controller.error.isNotEmpty) {
          return CustomErrorWidget(error: controller.error, onRetry: () => controller.retry());
        }

        return column.children([
          if (controller.hasSuggestions) _buildSuggestions(),
          Expanded(child: controller.hasResults ? _buildSearchResults() : _buildSearchHistory()),
        ]);
      }),
    );
  }

  Widget _buildSearchField() {
    return container.h40.grey100.rounded20.child(
      TextField(
        controller: controller.searchTextController,
        autofocus: true,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: '搜索漫画名、作者名',
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          suffixIcon: Icons.search.icon.s20.mk,
        ),
        onChanged: controller.getSuggestions,
        onSubmitted: controller.searchComics,
      ),
    );
  }

  Widget _buildSuggestions() {
    return container
        .maxHeight(200)
        .white
        .child(
          listview.shrinkWrap.dataBuilder(controller.suggestions, (_, __, suggestion) {
            return ListTile(
              dense: true,
              leading: Icons.search.icon.s20.mk,
              title: text(suggestion).mk,
              onTap: () => controller.selectSuggestion(suggestion),
            );
          }),
        );
  }

  Widget _buildSearchResults() {
    return column.children([
      container.centerLeft.p16.child(text('搜索结果 (${controller.searchResults.length})').f16.bold.mk),
      Expanded(
        child: controller.searchResults.isEmpty
            ? Center(child: column.center.children([Icons.search_off.icon.s64.grey.mk, text('没有找到相关漫画').f16.grey.mk]))
            : gridview.ph16.spacing12.ratio70.childWidth180.dataBuilder(controller.searchResults, (_, __, comic) {
                return ComicCard(
                  comic: comic,
                  onTap: () => Get.toNamed('/comic/${comic.id}', arguments: comic),
                );
              }),
      ),
    ]);
  }

  Widget _buildSearchHistory() {
    return column.children([
      if (controller.searchHistory.isNotEmpty)
        container.p16.child(
          row.spaceBetween.children([
            text('搜索历史').f16.bold.mk,
            textButton('清空').click(onTap: controller.clearSearchHistory),
          ]),
        ),
      Expanded(
        child: controller.searchHistory.isEmpty
            ? Center(
                child: column.center.spacing16.children([Icons.history.icon.s64.grey.mk, text('暂无搜索历史').f16.grey.mk]),
              )
            : listview.builder(controller.searchHistory.length, (context, index) {
                final query = controller.searchHistory[index];
                return ListTile(
                  leading: const Icon(Icons.history),
                  title: text(query).mk,
                  trailing: Icons.close.icon.s20.iconClick(onTap: () => controller.removeSearchHistoryItem(query)),
                  onTap: () => controller.selectHistory(query),
                );
              }),
      ),
    ]);
  }
}
