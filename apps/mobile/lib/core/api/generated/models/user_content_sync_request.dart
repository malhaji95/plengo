// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user_card_write.dart';
import 'user_deck_write.dart';

part 'user_content_sync_request.g.dart';

@JsonSerializable()
class UserContentSyncRequest {
  const UserContentSyncRequest({required this.decks, required this.cards});

  factory UserContentSyncRequest.fromJson(Map<String, Object?> json) => _$UserContentSyncRequestFromJson(json);

  final List<UserDeckWrite> decks;
  final List<UserCardWrite> cards;

  Map<String, Object?> toJson() => _$UserContentSyncRequestToJson(this);
}
