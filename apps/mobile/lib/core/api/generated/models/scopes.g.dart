// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'scopes.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Scopes _$ScopesFromJson(Map<String, dynamic> json) => Scopes(
  scope: OfflineScope.fromJson(json['scope'] as Map<String, dynamic>),
  titleAr: json['titleAr'] as String,
  sizeBytes: (json['sizeBytes'] as num).toInt(),
  packCount: (json['packCount'] as num).toInt(),
);

Map<String, dynamic> _$ScopesToJson(Scopes instance) => <String, dynamic>{
  'scope': instance.scope,
  'titleAr': instance.titleAr,
  'sizeBytes': instance.sizeBytes,
  'packCount': instance.packCount,
};
