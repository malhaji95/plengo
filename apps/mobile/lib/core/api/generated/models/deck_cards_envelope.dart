// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'deck_cards.dart';

part 'deck_cards_envelope.g.dart';

@JsonSerializable()
class DeckCardsEnvelope {
  const DeckCardsEnvelope({required this.success, required this.data, required this.error});

  factory DeckCardsEnvelope.fromJson(Map<String, Object?> json) => _$DeckCardsEnvelopeFromJson(json);

  final bool success;
  final DeckCards data;
  final dynamic error;

  Map<String, Object?> toJson() => _$DeckCardsEnvelopeToJson(this);
}
