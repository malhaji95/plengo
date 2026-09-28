// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_card.dart';
import 'offline_deck.dart';
import 'offline_item_type.dart';
import 'offline_question.dart';
import 'offline_quiz.dart';

part 'offline_item.g.dart';

@JsonSerializable()
class OfflineItem {
  const OfflineItem({
    required this.type,
    required this.id,
    required this.version,
    required this.question,
    required this.deck,
    required this.card,
    required this.quiz,
  });

  factory OfflineItem.fromJson(Map<String, Object?> json) => _$OfflineItemFromJson(json);

  final OfflineItemType type;
  final String id;
  final int version;
  @JsonKey(includeIfNull: true)
  final OfflineQuestion? question;
  @JsonKey(includeIfNull: true)
  final OfflineDeck? deck;
  @JsonKey(includeIfNull: true)
  final OfflineCard? card;
  @JsonKey(includeIfNull: true)
  final OfflineQuiz? quiz;

  Map<String, Object?> toJson() => _$OfflineItemToJson(this);
}
