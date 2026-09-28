// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'remote_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RemoteConfig _$RemoteConfigFromJson(Map<String, dynamic> json) => RemoteConfig(
  minSupportedVersion: MinSupportedVersion.fromJson(
    json['minSupportedVersion'] as Map<String, dynamic>,
  ),
  latestVersion: LatestVersion.fromJson(
    json['latestVersion'] as Map<String, dynamic>,
  ),
  features: Features.fromJson(json['features'] as Map<String, dynamic>),
  srsDefaults: SrsDefaults.fromJson(
    json['srsDefaults'] as Map<String, dynamic>,
  ),
  support: Support.fromJson(json['support'] as Map<String, dynamic>),
  storeUrls: StoreUrls.fromJson(json['storeUrls'] as Map<String, dynamic>),
  privacyPolicyUrl: json['privacyPolicyUrl'] as String,
  termsUrl: json['termsUrl'] as String,
);

Map<String, dynamic> _$RemoteConfigToJson(RemoteConfig instance) =>
    <String, dynamic>{
      'minSupportedVersion': instance.minSupportedVersion,
      'latestVersion': instance.latestVersion,
      'features': instance.features,
      'srsDefaults': instance.srsDefaults,
      'support': instance.support,
      'storeUrls': instance.storeUrls,
      'privacyPolicyUrl': instance.privacyPolicyUrl,
      'termsUrl': instance.termsUrl,
    };
