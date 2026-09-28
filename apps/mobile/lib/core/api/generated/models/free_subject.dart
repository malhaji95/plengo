// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'free_subject.g.dart';

@JsonSerializable()
class FreeSubject {
  const FreeSubject({required this.subjectId, required this.nameAr, required this.freeCount});

  factory FreeSubject.fromJson(Map<String, Object?> json) => _$FreeSubjectFromJson(json);

  final String subjectId;
  final String nameAr;
  final int freeCount;

  Map<String, Object?> toJson() => _$FreeSubjectToJson(this);
}
