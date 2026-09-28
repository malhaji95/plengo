// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'mistakes.g.dart';

@JsonSerializable()
class Mistakes {
  const Mistakes({required this.active, required this.mastered});

  factory Mistakes.fromJson(Map<String, Object?> json) => _$MistakesFromJson(json);

  final int active;
  final int mastered;

  Map<String, Object?> toJson() => _$MistakesToJson(this);
}
