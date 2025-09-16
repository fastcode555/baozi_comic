import 'package:baozi_comic/models/comic_image.dart';
import 'package:json_annotation/json_annotation.dart';

part 'chapter.g.dart';

@JsonSerializable()
class Chapter {
  final String id;
  final String title;
  final String comicId;
  final int? chapterNumber;
  final String? url;
  final List<String>? imageUrls;
  final List<ComicImage>? images; // 包含尺寸信息的图片列表
  final DateTime? publishDate;
  final int? totalPages; // 总页数
  final int? currentPage; // 当前页数

  Chapter({
    required this.id,
    required this.title,
    required this.comicId,
    this.chapterNumber,
    this.url,
    this.imageUrls,
    this.images,
    this.publishDate,
    this.totalPages,
    this.currentPage,
  });

  factory Chapter.fromJson(Map<String, dynamic> json) => _$ChapterFromJson(json);

  Map<String, dynamic> toJson() => _$ChapterToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Chapter && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Chapter{id: $id, title: $title, comicId: $comicId}';
  }
}
