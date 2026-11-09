// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_banner.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeBanner _$HomeBannerFromJson(Map<String, dynamic> json) => HomeBanner(
  id: json['id'] as String,
  titleAr: json['titleAr'] as String,
  imageUrl: json['imageUrl'] as String,
  width: (json['width'] as num?)?.toInt(),
  height: (json['height'] as num?)?.toInt(),
  action: $enumDecode(_$BannerActionEnumMap, json['action']),
  actionTarget: json['actionTarget'] as String?,
);

Map<String, dynamic> _$HomeBannerToJson(HomeBanner instance) =>
    <String, dynamic>{
      'id': instance.id,
      'titleAr': instance.titleAr,
      'imageUrl': instance.imageUrl,
      'width': instance.width,
      'height': instance.height,
      'action': instance.action,
      'actionTarget': instance.actionTarget,
    };

const _$BannerActionEnumMap = {
  BannerAction.subject: 'subject',
  BannerAction.teacher: 'teacher',
  BannerAction.teacherTrack: 'teacher_track',
  BannerAction.quiz: 'quiz',
  BannerAction.deck: 'deck',
  BannerAction.internalRoute: 'internal_route',
  BannerAction.externalUrl: 'external_url',
  BannerAction.none: 'none',
};
