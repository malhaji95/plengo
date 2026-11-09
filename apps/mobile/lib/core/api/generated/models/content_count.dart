// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'content_count.g.dart';

@JsonSerializable()
class ContentCount {
  const ContentCount({
    required this.total,
    required this.free,
  });
  
  factory ContentCount.fromJson(Map<String, Object?> json) => _$ContentCountFromJson(json);
  
  final int total;
  final int free;

  Map<String, Object?> toJson() => _$ContentCountToJson(this);
}
