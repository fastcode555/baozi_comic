// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'comic_image.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ComicImage _$ComicImageFromJson(Map<String, dynamic> json) => ComicImage(
  url: json['url'] as String,
  width: (json['width'] as num).toInt(),
  height: (json['height'] as num).toInt(),
  index: (json['index'] as num).toInt(),
);

Map<String, dynamic> _$ComicImageToJson(ComicImage instance) => <String, dynamic>{
  'url': instance.url,
  'width': instance.width,
  'height': instance.height,
  'index': instance.index,
};
