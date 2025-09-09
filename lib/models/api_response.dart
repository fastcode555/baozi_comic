import 'package:json_annotation/json_annotation.dart';

part 'api_response.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class ApiResponse<T> {
  final bool success;
  final String? message;
  final T? data;
  final int? code;

  const ApiResponse({
    required this.success,
    this.message,
    this.data,
    this.code,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$ApiResponseFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$ApiResponseToJson(this, toJsonT);

  factory ApiResponse.success(T data, {String? message}) {
    return ApiResponse(
      success: true,
      data: data,
      message: message,
      code: 200,
    );
  }

  factory ApiResponse.error(String message, {int? code}) {
    return ApiResponse(
      success: false,
      message: message,
      code: code ?? 400,
    );
  }

  @override
  String toString() {
    return 'ApiResponse{success: $success, message: $message, code: $code}';
  }
}
