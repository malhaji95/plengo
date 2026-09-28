// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'min_supported_version.g.dart';

@JsonSerializable()
class MinSupportedVersion {
  const MinSupportedVersion({required this.android, required this.ios, required this.web});

  factory MinSupportedVersion.fromJson(Map<String, Object?> json) => _$MinSupportedVersionFromJson(json);

  final String android;
  final String ios;
  final String web;

  Map<String, Object?> toJson() => _$MinSupportedVersionToJson(this);
}
