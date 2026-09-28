// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'exam_countdown.g.dart';

@JsonSerializable()
class ExamCountdown {
  const ExamCountdown({required this.titleAr, required this.examDate, required this.daysLeft});

  factory ExamCountdown.fromJson(Map<String, Object?> json) => _$ExamCountdownFromJson(json);

  final String titleAr;
  final String examDate;
  final int daysLeft;

  Map<String, Object?> toJson() => _$ExamCountdownToJson(this);
}
