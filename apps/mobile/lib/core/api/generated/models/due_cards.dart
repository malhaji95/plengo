// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'due_card.dart';

part 'due_cards.g.dart';

@JsonSerializable()
class DueCards {
  const DueCards({required this.cards, required this.urlsExpireAt});

  factory DueCards.fromJson(Map<String, Object?> json) => _$DueCardsFromJson(json);

  final List<DueCard> cards;
  final String urlsExpireAt;

  Map<String, Object?> toJson() => _$DueCardsToJson(this);
}
