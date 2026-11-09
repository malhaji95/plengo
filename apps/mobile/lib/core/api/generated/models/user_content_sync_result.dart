// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'sync_rejection.dart';

part 'user_content_sync_result.g.dart';

@JsonSerializable()
class UserContentSyncResult {
  const UserContentSyncResult({
    required this.appliedDecks,
    required this.appliedCards,
    required this.rejected,
  });
  
  factory UserContentSyncResult.fromJson(Map<String, Object?> json) => _$UserContentSyncResultFromJson(json);
  
  final int appliedDecks;
  final int appliedCards;
  final List<SyncRejection> rejected;

  Map<String, Object?> toJson() => _$UserContentSyncResultToJson(this);
}
