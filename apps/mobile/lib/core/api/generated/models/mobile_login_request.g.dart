// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mobile_login_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MobileLoginRequest _$MobileLoginRequestFromJson(Map<String, dynamic> json) =>
    MobileLoginRequest(
      email: json['email'] as String,
      password: json['password'] as String,
      platform: $enumDecode(
        _$MobileLoginRequestPlatformEnumMap,
        json['platform'],
      ),
      appVersion: json['appVersion'] as String?,
    );

Map<String, dynamic> _$MobileLoginRequestToJson(MobileLoginRequest instance) =>
    <String, dynamic>{
      'email': instance.email,
      'password': instance.password,
      'platform': instance.platform,
      'appVersion': ?instance.appVersion,
    };

const _$MobileLoginRequestPlatformEnumMap = {
  MobileLoginRequestPlatform.android: 'android',
  MobileLoginRequestPlatform.ios: 'ios',
};
