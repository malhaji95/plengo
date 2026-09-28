// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'offline_item_type.dart';

part 'items2.g.dart';

@JsonSerializable()
class Items2 {
  const Items2({
    required this.type,
    required this.id,
    required this.version,
  });
  
  factory Items2.fromJson(Map<String, Object?> json) => _$Items2FromJson(json);
  
  final OfflineItemType type;
  final String id;
  final int version;

  Map<String, Object?> toJson() => _$Items2ToJson(this);
}
