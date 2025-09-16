// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Chapter _$ChapterFromJson(Map<String, dynamic> json) => Chapter(
  id: json['id'] as String,
  title: json['title'] as String,
  comicId: json['comicId'] as String,
  chapterNumber: (json['chapterNumber'] as num?)?.toInt(),
  url: json['url'] as String?,
  imageUrls: (json['imageUrls'] as List<dynamic>?)?.map((e) => e as String).toList(),
  images: (json['images'] as List<dynamic>?)?.map((e) => ComicImage.fromJson(e as Map<String, dynamic>)).toList(),
  publishDate: json['publishDate'] == null ? null : DateTime.parse(json['publishDate'] as String),
  totalPages: (json['totalPages'] as num?)?.toInt(),
  currentPage: (json['currentPage'] as num?)?.toInt(),
);

Map<String, dynamic> _$ChapterToJson(Chapter instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'comicId': instance.comicId,
  'chapterNumber': instance.chapterNumber,
  'url': instance.url,
  'imageUrls': instance.imageUrls,
  'images': instance.images,
  'publishDate': instance.publishDate?.toIso8601String(),
  'totalPages': instance.totalPages,
  'currentPage': instance.currentPage,
};
