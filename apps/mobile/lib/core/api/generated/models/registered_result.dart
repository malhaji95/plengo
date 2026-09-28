// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'registered_result.g.dart';

@JsonSerializable()
class RegisteredResult {
  const RegisteredResult({required this.registered});

  factory RegisteredResult.fromJson(Map<String, Object?> json) => _$RegisteredResultFromJson(json);

  final bool registered;

  Map<String, Object?> toJson() => _$RegisteredResultToJson(this);
}
