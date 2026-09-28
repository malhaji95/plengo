// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'support.g.dart';

@JsonSerializable()
class Support {
  const Support({required this.email, required this.whatsapp});

  factory Support.fromJson(Map<String, Object?> json) => _$SupportFromJson(json);

  final String email;
  final String whatsapp;

  Map<String, Object?> toJson() => _$SupportToJson(this);
}
