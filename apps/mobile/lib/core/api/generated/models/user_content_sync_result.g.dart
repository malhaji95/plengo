// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_content_sync_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserContentSyncResult _$UserContentSyncResultFromJson(
  Map<String, dynamic> json,
) => UserContentSyncResult(
  appliedDecks: (json['appliedDecks'] as num).toInt(),
  appliedCards: (json['appliedCards'] as num).toInt(),
  rejected: (json['rejected'] as List<dynamic>)
      .map((e) => SyncRejection.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UserContentSyncResultToJson(
  UserContentSyncResult instance,
) => <String, dynamic>{
  'appliedDecks': instance.appliedDecks,
  'appliedCards': instance.appliedCards,
  'rejected': instance.rejected,
};
