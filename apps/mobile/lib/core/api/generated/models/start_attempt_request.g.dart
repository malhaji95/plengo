// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'start_attempt_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StartAttemptRequest _$StartAttemptRequestFromJson(Map<String, dynamic> json) =>
    StartAttemptRequest(
      clientAttemptId: json['clientAttemptId'] as String,
      source: $enumDecode(_$StartAttemptRequestSourceEnumMap, json['source']),
      mode: $enumDecode(_$StartAttemptRequestModeEnumMap, json['mode']),
      quizId: json['quizId'] as String?,
      filters: json['filters'] == null
          ? null
          : AttemptFilters.fromJson(json['filters'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$StartAttemptRequestToJson(
  StartAttemptRequest instance,
) => <String, dynamic>{
  'clientAttemptId': instance.clientAttemptId,
  'source': _$StartAttemptRequestSourceEnumMap[instance.source]!,
  'mode': _$StartAttemptRequestModeEnumMap[instance.mode]!,
  'quizId': ?instance.quizId,
  'filters': ?instance.filters,
};

const _$StartAttemptRequestSourceEnumMap = {
  StartAttemptRequestSource.curated: 'curated',
  StartAttemptRequestSource.random: 'random',
  StartAttemptRequestSource.mistakes: 'mistakes',
};

const _$StartAttemptRequestModeEnumMap = {
  StartAttemptRequestMode.practice: 'practice',
  StartAttemptRequestMode.exam: 'exam',
};
