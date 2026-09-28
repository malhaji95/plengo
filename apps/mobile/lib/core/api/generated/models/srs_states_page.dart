// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'srs_card_state.dart';

part 'srs_states_page.g.dart';

@JsonSerializable()
class SrsStatesPage {
  const SrsStatesPage({required this.items, required this.nextCursor});

  factory SrsStatesPage.fromJson(Map<String, Object?> json) => _$SrsStatesPageFromJson(json);

  final List<SrsCardState> items;
  @JsonKey(includeIfNull: true)
  final String? nextCursor;

  Map<String, Object?> toJson() => _$SrsStatesPageToJson(this);
}
