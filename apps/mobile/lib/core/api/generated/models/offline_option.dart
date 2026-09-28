// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'offline_option.g.dart';

@JsonSerializable()
class OfflineOption {
  const OfflineOption({required this.id, required this.text, required this.isCorrect});

  factory OfflineOption.fromJson(Map<String, Object?> json) => _$OfflineOptionFromJson(json);

  final String id;
  final String text;
  final bool isCorrect;

  Map<String, Object?> toJson() => _$OfflineOptionToJson(this);
}
