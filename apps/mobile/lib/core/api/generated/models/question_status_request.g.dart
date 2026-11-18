// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'question_status_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

QuestionStatusRequest _$QuestionStatusRequestFromJson(
  Map<String, dynamic> json,
) => QuestionStatusRequest(
  status: $enumDecode(_$QuestionStatusRequestStatusEnumMap, json['status']),
);

Map<String, dynamic> _$QuestionStatusRequestToJson(
  QuestionStatusRequest instance,
) => <String, dynamic>{'status': instance.status};

const _$QuestionStatusRequestStatusEnumMap = {
  QuestionStatusRequestStatus.draft: 'draft',
  QuestionStatusRequestStatus.published: 'published',
  QuestionStatusRequestStatus.archived: 'archived',
};
