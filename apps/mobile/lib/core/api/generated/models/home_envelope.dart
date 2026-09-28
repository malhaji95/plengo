// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'home.dart';

part 'home_envelope.g.dart';

@JsonSerializable()
class HomeEnvelope {
  const HomeEnvelope({required this.success, required this.data, required this.error});

  factory HomeEnvelope.fromJson(Map<String, Object?> json) => _$HomeEnvelopeFromJson(json);

  final bool success;
  final Home data;
  final dynamic error;

  Map<String, Object?> toJson() => _$HomeEnvelopeToJson(this);
}
