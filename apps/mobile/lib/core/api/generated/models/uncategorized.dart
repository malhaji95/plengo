// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'uncategorized.g.dart';

@JsonSerializable()
class Uncategorized {
  const Uncategorized({
    required this.questionCount,
    required this.accessibleCount,
  });
  
  factory Uncategorized.fromJson(Map<String, Object?> json) => _$UncategorizedFromJson(json);
  
  final int questionCount;
  final int accessibleCount;

  Map<String, Object?> toJson() => _$UncategorizedToJson(this);
}
