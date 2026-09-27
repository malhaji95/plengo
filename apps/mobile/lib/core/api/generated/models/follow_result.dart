// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'follow_result.g.dart';

@JsonSerializable()
class FollowResult {
  const FollowResult({
    required this.following,
    required this.followerCount,
  });
  
  factory FollowResult.fromJson(Map<String, Object?> json) => _$FollowResultFromJson(json);
  
  final bool following;
  final num followerCount;

  Map<String, Object?> toJson() => _$FollowResultToJson(this);
}
