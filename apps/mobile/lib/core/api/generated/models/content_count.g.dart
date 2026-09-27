// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'content_count.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ContentCount _$ContentCountFromJson(Map<String, dynamic> json) => ContentCount(
  total: (json['total'] as num).toInt(),
  free: (json['free'] as num).toInt(),
);

Map<String, dynamic> _$ContentCountToJson(ContentCount instance) =>
    <String, dynamic>{'total': instance.total, 'free': instance.free};
