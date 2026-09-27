// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_answer_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckAnswerRequest _$CheckAnswerRequestFromJson(Map<String, dynamic> json) =>
    CheckAnswerRequest(
      selectedOptionId: json['selectedOptionId'] as String?,
      writtenAnswer: json['writtenAnswer'] as String?,
    );

Map<String, dynamic> _$CheckAnswerRequestToJson(CheckAnswerRequest instance) =>
    <String, dynamic>{
      'selectedOptionId': ?instance.selectedOptionId,
      'writtenAnswer': ?instance.writtenAnswer,
    };
