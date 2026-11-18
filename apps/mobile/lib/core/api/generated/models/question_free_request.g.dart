// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_free_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionFreeRequest _$QuestionFreeRequestFromJson(Map<String, dynamic> json) =>
    QuestionFreeRequest(
      mode: $enumDecode(_$QuestionFreeRequestModeEnumMap, json['mode']),
    );

Map<String, dynamic> _$QuestionFreeRequestToJson(
  QuestionFreeRequest instance,
) => <String, dynamic>{'mode': instance.mode};

const _$QuestionFreeRequestModeEnumMap = {
  QuestionFreeRequestMode.rule: 'rule',
  QuestionFreeRequestMode.free: 'free',
  QuestionFreeRequestMode.paid: 'paid',
};
