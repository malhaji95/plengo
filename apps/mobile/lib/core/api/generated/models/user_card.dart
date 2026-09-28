// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user_card_face.dart';
import 'user_card_kind.dart';

part 'user_card.g.dart';

@JsonSerializable()
class UserCard {
  const UserCard({
    required this.id,
    required this.deckId,
    required this.kind,
    required this.officialFlashcardId,
    required this.locked,
    required this.front,
    required this.back,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt,
  });
  
  factory UserCard.fromJson(Map<String, Object?> json) => _$UserCardFromJson(json);
  
  final String id;
  final String deckId;
  final UserCardKind kind;
  @JsonKey(includeIfNull: true)
  final String? officialFlashcardId;
  final bool locked;
  final UserCardFace front;
  final UserCardFace back;
  final int sortOrder;
  final String createdAt;
  final String updatedAt;
  @JsonKey(includeIfNull: true)
  final String? deletedAt;

  Map<String, Object?> toJson() => _$UserCardToJson(this);
}
