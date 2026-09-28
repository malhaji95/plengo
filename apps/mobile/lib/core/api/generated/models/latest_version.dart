// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'latest_version.g.dart';

@JsonSerializable()
class LatestVersion {
  const LatestVersion({required this.android, required this.ios, required this.web});

  factory LatestVersion.fromJson(Map<String, Object?> json) => _$LatestVersionFromJson(json);

  final String android;
  final String ios;
  final String web;

  Map<String, Object?> toJson() => _$LatestVersionToJson(this);
}
