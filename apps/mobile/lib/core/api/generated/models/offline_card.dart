// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_image.dart';

part 'offline_card.g.dart';

@JsonSerializable()
class OfflineCard {
  const OfflineCard({
    required this.id,
    required this.deckId,
    required this.sortOrder,
    required this.front,
    required this.back,
  });

  factory OfflineCard.fromJson(Map<String, Object?> json) => _$OfflineCardFromJson(json);

  final String id;
  final String deckId;
  final int sortOrder;
  final OfflineImage front;
  final OfflineImage back;

  Map<String, Object?> toJson() => _$OfflineCardToJson(this);
}
