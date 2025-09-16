// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchResult _$SearchResultFromJson(Map<String, dynamic> json) => SearchResult(
  comics: (json['comics'] as List<dynamic>).map((e) => Comic.fromJson(e as Map<String, dynamic>)).toList(),
  query: json['query'] as String?,
  totalCount: (json['totalCount'] as num?)?.toInt(),
  currentPage: (json['currentPage'] as num?)?.toInt(),
  totalPages: (json['totalPages'] as num?)?.toInt(),
);

Map<String, dynamic> _$SearchResultToJson(SearchResult instance) => <String, dynamic>{
  'comics': instance.comics,
  'query': instance.query,
  'totalCount': instance.totalCount,
  'currentPage': instance.currentPage,
  'totalPages': instance.totalPages,
};
