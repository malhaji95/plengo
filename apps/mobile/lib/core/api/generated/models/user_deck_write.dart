// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'user_deck_write.g.dart';

@JsonSerializable()
class UserDeckWrite {
  const UserDeckWrite({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.subjectId,
    this.color,
    this.deletedAt,
  });
  
  factory UserDeckWrite.fromJson(Map<String, Object?> json) => _$UserDeckWriteFromJson(json);
  
  final String id;
  final String name;
  @JsonKey(includeIfNull: false)
  final String? subjectId;
  @JsonKey(includeIfNull: false)
  final String? color;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  @JsonKey(includeIfNull: false)
  final DateTime? deletedAt;

  Map<String, Object?> toJson() => _$UserDeckWriteToJson(this);
}
