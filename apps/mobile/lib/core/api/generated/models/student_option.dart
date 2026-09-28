// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'student_option.g.dart';

@JsonSerializable()
class StudentOption {
  const StudentOption({required this.id, required this.text});

  factory StudentOption.fromJson(Map<String, Object?> json) => _$StudentOptionFromJson(json);

  final String id;
  final String text;

  Map<String, Object?> toJson() => _$StudentOptionToJson(this);
}
