// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'options.g.dart';

@JsonSerializable()
class Options {
  const Options({
    required this.id,
    required this.text,
    required this.isCorrect,
  });
  
  factory Options.fromJson(Map<String, Object?> json) => _$OptionsFromJson(json);
  
  final String id;
  final String text;
  final bool isCorrect;

  Map<String, Object?> toJson() => _$OptionsToJson(this);
}
