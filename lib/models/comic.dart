import 'package:json_annotation/json_annotation.dart';

part 'comic.g.dart';

@JsonSerializable()
class Comic {
  final String id;
  final String title;
  final String? coverUrl;
  final String? author;
  final String? status;
  final String? description;
  final List<String>? tags;
  final String? latestChapter;
  final String? lastUpdate; // 显示"更新至第xx话"等信息
  final String? category;
  final int? ranking;

  Comic({
    required this.id,
    required this.title,
    this.coverUrl,
    this.author,
    this.status,
    this.description,
    this.tags,
    this.latestChapter,
    this.lastUpdate,
    this.category,
    this.ranking,
  });

  factory Comic.fromJson(Map<String, dynamic> json) => _$ComicFromJson(json);

  Map<String, dynamic> toJson() => _$ComicToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Comic && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Comic{id: $id, title: $title, status: $status}';
  }
}
