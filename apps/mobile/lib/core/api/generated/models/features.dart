// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'features.g.dart';

@JsonSerializable()
class Features {
  const Features({
    required this.teacherFollowing,
    required this.randomPractice,
    required this.studentDecks,
    required this.streaks,
    required this.contentReports,
  });
  
  factory Features.fromJson(Map<String, Object?> json) => _$FeaturesFromJson(json);
  
  final bool teacherFollowing;
  final bool randomPractice;
  final bool studentDecks;
  final bool streaks;
  final bool contentReports;

  Map<String, Object?> toJson() => _$FeaturesToJson(this);
}
