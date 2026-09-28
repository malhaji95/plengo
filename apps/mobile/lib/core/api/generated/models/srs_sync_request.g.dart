// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'srs_sync_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SrsSyncRequest _$SrsSyncRequestFromJson(Map<String, dynamic> json) => SrsSyncRequest(
  logs: (json['logs'] as List<dynamic>).map((e) => ReviewLog.fromJson(e as Map<String, dynamic>)).toList(),
  states: (json['states'] as List<dynamic>).map((e) => SrsSyncState.fromJson(e as Map<String, dynamic>)).toList(),
);

Map<String, dynamic> _$SrsSyncRequestToJson(SrsSyncRequest instance) => <String, dynamic>{
  'logs': instance.logs,
  'states': instance.states,
};
