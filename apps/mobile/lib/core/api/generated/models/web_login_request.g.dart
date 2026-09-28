// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'web_login_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebLoginRequest _$WebLoginRequestFromJson(Map<String, dynamic> json) =>
    WebLoginRequest(email: json['email'] as String, password: json['password'] as String);

Map<String, dynamic> _$WebLoginRequestToJson(WebLoginRequest instance) => <String, dynamic>{
  'email': instance.email,
  'password': instance.password,
};
