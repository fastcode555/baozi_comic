import 'package:json_annotation/json_annotation.dart';

part 'reading_history.g.dart';

@JsonSerializable()
class ReadingHistory {
  final String comicId;
  final String comicTitle;
  final String? comicCoverUrl;
  final String? lastChapterId;
  final String? lastChapterTitle;
  final int? lastReadPage;
  final DateTime lastReadTime;

  const ReadingHistory({
    required this.comicId,
    required this.comicTitle,
    this.comicCoverUrl,
    this.lastChapterId,
    this.lastChapterTitle,
    this.lastReadPage,
    required this.lastReadTime,
  });

  factory ReadingHistory.fromJson(Map<String, dynamic> json) => _$ReadingHistoryFromJson(json);
  Map<String, dynamic> toJson() => _$ReadingHistoryToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReadingHistory && 
      runtimeType == other.runtimeType && 
      comicId == other.comicId;

  @override
  int get hashCode => comicId.hashCode;

  @override
  String toString() {
    return 'ReadingHistory{comicId: $comicId, comicTitle: $comicTitle, lastReadTime: $lastReadTime}';
  }
}
