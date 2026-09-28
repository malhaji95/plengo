// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'srs_card_state.dart';
import 'user_card.dart';

part 'due_user_card.g.dart';

@JsonSerializable()
class DueUserCard {
  const DueUserCard({required this.card, required this.deckName, required this.state});

  factory DueUserCard.fromJson(Map<String, Object?> json) => _$DueUserCardFromJson(json);

  final UserCard card;
  final String deckName;
  final SrsCardState state;

  Map<String, Object?> toJson() => _$DueUserCardToJson(this);
}
