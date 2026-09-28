// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'user_deck_list.dart';

part 'user_deck_list_envelope.g.dart';

@JsonSerializable()
class UserDeckListEnvelope {
  const UserDeckListEnvelope({
    required this.success,
    required this.data,
    required this.error,
  });
  
  factory UserDeckListEnvelope.fromJson(Map<String, Object?> json) => _$UserDeckListEnvelopeFromJson(json);
  
  final bool success;
  final UserDeckList data;
  final dynamic error;

  Map<String, Object?> toJson() => _$UserDeckListEnvelopeToJson(this);
}
