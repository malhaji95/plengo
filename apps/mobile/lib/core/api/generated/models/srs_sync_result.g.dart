// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'srs_sync_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SrsSyncResult _$SrsSyncResultFromJson(Map<String, dynamic> json) =>
    SrsSyncResult(
      acceptedLogs: (json['acceptedLogs'] as num).toInt(),
      appliedStates: (json['appliedStates'] as num).toInt(),
      states: (json['states'] as List<dynamic>)
          .map((e) => SrsCardState.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$SrsSyncResultToJson(SrsSyncResult instance) =>
    <String, dynamic>{
      'acceptedLogs': instance.acceptedLogs,
      'appliedStates': instance.appliedStates,
      'states': instance.states,
    };
