// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'due_cards.dart';

part 'due_cards_envelope.g.dart';

@JsonSerializable()
class DueCardsEnvelope {
  const DueCardsEnvelope({required this.success, required this.data, required this.error});

  factory DueCardsEnvelope.fromJson(Map<String, Object?> json) => _$DueCardsEnvelopeFromJson(json);

  final bool success;
  final DueCards data;
  final dynamic error;

  Map<String, Object?> toJson() => _$DueCardsEnvelopeToJson(this);
}
