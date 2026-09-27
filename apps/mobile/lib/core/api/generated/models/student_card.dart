// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'card_image.dart';

part 'student_card.g.dart';

@JsonSerializable()
class StudentCard {
  const StudentCard({
    required this.id,
    required this.deckId,
    required this.sortOrder,
    required this.contentVersion,
    required this.front,
    required this.back,
  });
  
  factory StudentCard.fromJson(Map<String, Object?> json) => _$StudentCardFromJson(json);
  
  final String id;
  final String deckId;
  final int sortOrder;
  final int contentVersion;
  final CardImage front;
  final CardImage back;

  Map<String, Object?> toJson() => _$StudentCardToJson(this);
}
