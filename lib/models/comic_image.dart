import 'package:json_annotation/json_annotation.dart';

part 'comic_image.g.dart';

/// 漫画图片信息
@JsonSerializable()
class ComicImage {
  /// 图片URL
  final String url;
  
  /// 图片宽度
  final int width;
  
  /// 图片高度
  final int height;
  
  /// 图片索引
  final int index;
  
  /// 宽高比
  double get aspectRatio => height > 0 ? width / height : 1.0;
  
  const ComicImage({
    required this.url,
    required this.width,
    required this.height,
    required this.index,
  });
  
  factory ComicImage.fromJson(Map<String, dynamic> json) => _$ComicImageFromJson(json);
  
  Map<String, dynamic> toJson() => _$ComicImageToJson(this);
}
