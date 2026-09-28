// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'srs_defaults.g.dart';

@JsonSerializable()
class SrsDefaults {
  const SrsDefaults({required this.newCardsPerDay, required this.maxReviewsPerDay});

  factory SrsDefaults.fromJson(Map<String, Object?> json) => _$SrsDefaultsFromJson(json);

  final int newCardsPerDay;
  final int maxReviewsPerDay;

  Map<String, Object?> toJson() => _$SrsDefaultsToJson(this);
}
