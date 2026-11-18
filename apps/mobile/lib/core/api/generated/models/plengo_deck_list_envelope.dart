// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'plengo_deck_list.dart';

part 'plengo_deck_list_envelope.g.dart';

@JsonSerializable()
class PlengoDeckListEnvelope {
  const PlengoDeckListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory PlengoDeckListEnvelope.fromJson(Map<String, Object?> json) => _$PlengoDeckListEnvelopeFromJson(json);
  
  final bool success;
  final PlengoDeckList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$PlengoDeckListEnvelopeToJson(this);
}
