// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'signed_in_result.g.dart';

@JsonSerializable()
class SignedInResult {
  const SignedInResult({required this.signedIn});

  factory SignedInResult.fromJson(Map<String, Object?> json) => _$SignedInResultFromJson(json);

  final bool signedIn;

  Map<String, Object?> toJson() => _$SignedInResultToJson(this);
}
