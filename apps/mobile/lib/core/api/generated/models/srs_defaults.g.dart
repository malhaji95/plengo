// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'srs_defaults.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SrsDefaults _$SrsDefaultsFromJson(Map<String, dynamic> json) => SrsDefaults(
  newCardsPerDay: (json['newCardsPerDay'] as num).toInt(),
  maxReviewsPerDay: (json['maxReviewsPerDay'] as num).toInt(),
);

Map<String, dynamic> _$SrsDefaultsToJson(SrsDefaults instance) => <String, dynamic>{
  'newCardsPerDay': instance.newCardsPerDay,
  'maxReviewsPerDay': instance.maxReviewsPerDay,
};
