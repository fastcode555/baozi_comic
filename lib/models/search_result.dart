import 'package:json_annotation/json_annotation.dart';
import 'comic.dart';

part 'search_result.g.dart';

@JsonSerializable()
class SearchResult {
  final List<Comic> comics;
  final String? query;
  final int? totalCount;
  final int? currentPage;
  final int? totalPages;

  const SearchResult({
    required this.comics,
    this.query,
    this.totalCount,
    this.currentPage,
    this.totalPages,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => _$SearchResultFromJson(json);
  Map<String, dynamic> toJson() => _$SearchResultToJson(this);

  @override
  String toString() {
    return 'SearchResult{comics: ${comics.length}, query: $query, totalCount: $totalCount}';
  }
}
