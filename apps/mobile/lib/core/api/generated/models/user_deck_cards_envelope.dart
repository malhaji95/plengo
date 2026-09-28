// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user_deck_cards.dart';

part 'user_deck_cards_envelope.g.dart';

@JsonSerializable()
class UserDeckCardsEnvelope {
  const UserDeckCardsEnvelope({required this.success, required this.data, required this.error});

  factory UserDeckCardsEnvelope.fromJson(Map<String, Object?> json) => _$UserDeckCardsEnvelopeFromJson(json);

  final bool success;
  final UserDeckCards data;
  final dynamic error;

  Map<String, Object?> toJson() => _$UserDeckCardsEnvelopeToJson(this);
}
