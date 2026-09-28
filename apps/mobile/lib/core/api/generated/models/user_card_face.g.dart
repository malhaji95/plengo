// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_card_face.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UserCardFace _$UserCardFaceFromJson(Map<String, dynamic> json) => UserCardFace(
  text: json['text'] as String?,
  mediaId: json['mediaId'] as String?,
  image: json['image'] == null
      ? null
      : CardImage.fromJson(json['image'] as Map<String, dynamic>),
);

Map<String, dynamic> _$UserCardFaceToJson(UserCardFace instance) =>
    <String, dynamic>{
      'text': instance.text,
      'mediaId': instance.mediaId,
      'image': instance.image,
    };
