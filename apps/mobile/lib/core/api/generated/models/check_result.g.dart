// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckResult _$CheckResultFromJson(Map<String, dynamic> json) => CheckResult(
  isCorrect: json['isCorrect'] as bool,
  correctOptionId: json['correctOptionId'] as String?,
  correctAnswer: json['correctAnswer'] as String?,
  explanation: json['explanation'] as String?,
);

Map<String, dynamic> _$CheckResultToJson(CheckResult instance) => <String, dynamic>{
  'isCorrect': instance.isCorrect,
  'correctOptionId': instance.correctOptionId,
  'correctAnswer': instance.correctAnswer,
  'explanation': instance.explanation,
};
