// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user_card.dart';
import 'user_deck.dart';

part 'user_content_changes.g.dart';

@JsonSerializable()
class UserContentChanges {
  const UserContentChanges({
    required this.decks,
    required this.cards,
    required this.cursor,
    required this.hasMore,
    required this.urlsExpireAt,
  });

  factory UserContentChanges.fromJson(Map<String, Object?> json) => _$UserContentChangesFromJson(json);

  final List<UserDeck> decks;
  final List<UserCard> cards;
  final String cursor;
  final bool hasMore;
  final String urlsExpireAt;

  Map<String, Object?> toJson() => _$UserContentChangesToJson(this);
}
