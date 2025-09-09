// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReadingHistory _$ReadingHistoryFromJson(Map<String, dynamic> json) =>
    ReadingHistory(
      comicId: json['comicId'] as String,
      comicTitle: json['comicTitle'] as String,
      comicCoverUrl: json['comicCoverUrl'] as String?,
      lastChapterId: json['lastChapterId'] as String?,
      lastChapterTitle: json['lastChapterTitle'] as String?,
      lastReadPage: (json['lastReadPage'] as num?)?.toInt(),
      lastReadTime: DateTime.parse(json['lastReadTime'] as String),
    );

Map<String, dynamic> _$ReadingHistoryToJson(ReadingHistory instance) =>
    <String, dynamic>{
      'comicId': instance.comicId,
      'comicTitle': instance.comicTitle,
      'comicCoverUrl': instance.comicCoverUrl,
      'lastChapterId': instance.lastChapterId,
      'lastChapterTitle': instance.lastChapterTitle,
      'lastReadPage': instance.lastReadPage,
      'lastReadTime': instance.lastReadTime.toIso8601String(),
    };
