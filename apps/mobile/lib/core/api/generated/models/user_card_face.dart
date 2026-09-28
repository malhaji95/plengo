// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'card_image.dart';

part 'user_card_face.g.dart';

@JsonSerializable()
class UserCardFace {
  const UserCardFace({required this.text, required this.mediaId, required this.image});

  factory UserCardFace.fromJson(Map<String, Object?> json) => _$UserCardFaceFromJson(json);

  @JsonKey(includeIfNull: true)
  final String? text;
  @JsonKey(includeIfNull: true)
  final String? mediaId;
  @JsonKey(includeIfNull: true)
  final CardImage? image;

  Map<String, Object?> toJson() => _$UserCardFaceToJson(this);
}
