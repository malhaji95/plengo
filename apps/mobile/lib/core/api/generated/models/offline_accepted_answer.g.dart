// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_accepted_answer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflineAcceptedAnswer _$OfflineAcceptedAnswerFromJson(
  Map<String, dynamic> json,
) => OfflineAcceptedAnswer(
  original: json['original'] as String,
  normalized: json['normalized'] as String,
  normalizationVersion: (json['normalizationVersion'] as num).toInt(),
);

Map<String, dynamic> _$OfflineAcceptedAnswerToJson(
  OfflineAcceptedAnswer instance,
) => <String, dynamic>{
  'original': instance.original,
  'normalized': instance.normalized,
  'normalizationVersion': instance.normalizationVersion,
};
