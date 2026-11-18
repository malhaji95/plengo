// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'plengo_deck_group.dart';

part 'plengo_deck_list.g.dart';

@JsonSerializable()
class PlengoDeckList {
  const PlengoDeckList({
    required this.groups,
  });
  
  factory PlengoDeckList.fromJson(Map<String, Object?> json) => _$PlengoDeckListFromJson(json);
  
  final List<PlengoDeckGroup> groups;

  Map<String, Object?> toJson() => _$PlengoDeckListToJson(this);
}
