// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'by_state.g.dart';

@JsonSerializable()
class ByState {
  const ByState({required this.newValue, required this.learning, required this.review, required this.relearning});

  factory ByState.fromJson(Map<String, Object?> json) => _$ByStateFromJson(json);

  /// The name has been replaced because it contains a keyword. Original name: `new`.
  @JsonKey(name: 'new')
  final int newValue;
  final int learning;
  final int review;
  final int relearning;

  Map<String, Object?> toJson() => _$ByStateToJson(this);
}
