// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'accepted_answers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AcceptedAnswers _$AcceptedAnswersFromJson(Map<String, dynamic> json) =>
    AcceptedAnswers(
      original: json['original'] as String,
      normalized: json['normalized'] as String,
      normalizationVersion: (json['normalizationVersion'] as num).toInt(),
    );

Map<String, dynamic> _$AcceptedAnswersToJson(AcceptedAnswers instance) =>
    <String, dynamic>{
      'original': instance.original,
      'normalized': instance.normalized,
      'normalizationVersion': instance.normalizationVersion,
    };
