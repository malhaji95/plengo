// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

@JsonEnum()
enum ReportReason {
  @JsonValue('wrong_answer')
  wrongAnswer('wrong_answer'),
  @JsonValue('typo')
  typo('typo'),
  @JsonValue('unclear')
  unclear('unclear'),
  @JsonValue('image_problem')
  imageProblem('image_problem'),
  @JsonValue('other')
  other('other');

  const ReportReason(this.json);

  final String? json;
  String toJson() {
    final value = json;
    if (value == null) {
      throw StateError('Cannot convert enum value with null JSON representation to String. '
          'This usually happens for \$unknown or @JsonValue(null) entries.');
    }
    return value as String;
  }

  @override
  String toString() => json?.toString() ?? super.toString();
}
