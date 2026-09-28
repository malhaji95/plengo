// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

part 'signed_out_result.g.dart';

@JsonSerializable()
class SignedOutResult {
  const SignedOutResult({
    required this.signedOut,
  });
  
  factory SignedOutResult.fromJson(Map<String, Object?> json) => _$SignedOutResultFromJson(json);
  
  final bool signedOut;

  Map<String, Object?> toJson() => _$SignedOutResultToJson(this);
}
