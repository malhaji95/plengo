// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum SrsStateState {
  /// The name has been replaced because it contains a keyword. Original name: `new`.
  @JsonValue('new')
  valueNew,
  @JsonValue('learning')
  learning,
  @JsonValue('review')
  review,
  @JsonValue('relearning')
  relearning;
}
