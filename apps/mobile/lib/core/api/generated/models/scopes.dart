// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_scope.dart';

part 'scopes.g.dart';

@JsonSerializable()
class Scopes {
  const Scopes({
    required this.scope,
    required this.titleAr,
    required this.sizeBytes,
    required this.packCount,
  });
  
  factory Scopes.fromJson(Map<String, Object?> json) => _$ScopesFromJson(json);
  
  final OfflineScope scope;
  final String titleAr;
  final int sizeBytes;
  final int packCount;

  Map<String, Object?> toJson() => _$ScopesToJson(this);
}
