// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'srs_card_state.dart';
import 'student_card.dart';

part 'due_card.g.dart';

@JsonSerializable()
class DueCard {
  const DueCard({
    required this.card,
    required this.deckTitleAr,
    required this.subjectId,
    required this.subjectNameAr,
    required this.state,
  });
  
  factory DueCard.fromJson(Map<String, Object?> json) => _$DueCardFromJson(json);
  
  final StudentCard card;
  final String deckTitleAr;
  final String subjectId;
  final String subjectNameAr;
  final SrsCardState state;

  Map<String, Object?> toJson() => _$DueCardToJson(this);
}
