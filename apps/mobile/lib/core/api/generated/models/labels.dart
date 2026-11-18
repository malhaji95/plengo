// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'labels.g.dart';

@JsonSerializable()
class Labels {
  const Labels({
    required this.number,
    required this.answers,
  });
  
  factory Labels.fromJson(Map<String, Object?> json) => _$LabelsFromJson(json);
  
  final int number;
  final List<String> answers;

  Map<String, Object?> toJson() => _$LabelsToJson(this);
}
