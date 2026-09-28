// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_content_sync_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserContentSyncRequest _$UserContentSyncRequestFromJson(Map<String, dynamic> json) => UserContentSyncRequest(
  decks: (json['decks'] as List<dynamic>).map((e) => UserDeckWrite.fromJson(e as Map<String, dynamic>)).toList(),
  cards: (json['cards'] as List<dynamic>).map((e) => UserCardWrite.fromJson(e as Map<String, dynamic>)).toList(),
);

Map<String, dynamic> _$UserContentSyncRequestToJson(UserContentSyncRequest instance) => <String, dynamic>{
  'decks': instance.decks,
  'cards': instance.cards,
};
