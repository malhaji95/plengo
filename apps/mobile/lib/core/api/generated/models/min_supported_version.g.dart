// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'min_supported_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MinSupportedVersion _$MinSupportedVersionFromJson(Map<String, dynamic> json) =>
    MinSupportedVersion(
      android: json['android'] as String,
      ios: json['ios'] as String,
      web: json['web'] as String,
    );

Map<String, dynamic> _$MinSupportedVersionToJson(
  MinSupportedVersion instance,
) => <String, dynamic>{
  'android': instance.android,
  'ios': instance.ios,
  'web': instance.web,
};
