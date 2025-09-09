// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comic.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Comic _$ComicFromJson(Map<String, dynamic> json) => Comic(
  id: json['id'] as String,
  title: json['title'] as String,
  coverUrl: json['coverUrl'] as String?,
  author: json['author'] as String?,
  status: json['status'] as String?,
  description: json['description'] as String?,
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  latestChapter: json['latestChapter'] as String?,
  lastUpdate: json['lastUpdate'] as String?,
  category: json['category'] as String?,
  ranking: (json['ranking'] as num?)?.toInt(),
);

Map<String, dynamic> _$ComicToJson(Comic instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'coverUrl': instance.coverUrl,
  'author': instance.author,
  'status': instance.status,
  'description': instance.description,
  'tags': instance.tags,
  'latestChapter': instance.latestChapter,
  'lastUpdate': instance.lastUpdate,
  'category': instance.category,
  'ranking': instance.ranking,
};
