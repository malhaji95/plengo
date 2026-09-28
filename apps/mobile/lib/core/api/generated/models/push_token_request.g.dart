// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'push_token_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PushTokenRequest _$PushTokenRequestFromJson(Map<String, dynamic> json) => PushTokenRequest(
  token: json['token'] as String,
  platform: $enumDecode(_$PushTokenRequestPlatformEnumMap, json['platform']),
  appVersion: json['appVersion'] as String?,
);

Map<String, dynamic> _$PushTokenRequestToJson(PushTokenRequest instance) => <String, dynamic>{
  'token': instance.token,
  'platform': instance.platform,
  'appVersion': ?instance.appVersion,
};

const _$PushTokenRequestPlatformEnumMap = {
  PushTokenRequestPlatform.android: 'android',
  PushTokenRequestPlatform.ios: 'ios',
  PushTokenRequestPlatform.web: 'web',
};
