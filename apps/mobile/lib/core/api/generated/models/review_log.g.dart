// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_log.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReviewLog _$ReviewLogFromJson(Map<String, dynamic> json) => ReviewLog(
  id: json['id'] as String,
  flashcardId: json['flashcardId'] as String,
  rating: $enumDecode(_$ReviewLogRatingEnumMap, json['rating']),
  stateBefore: SrsState.fromJson(json['stateBefore'] as Map<String, dynamic>),
  stateAfter: SrsState.fromJson(json['stateAfter'] as Map<String, dynamic>),
  reviewedAt: DateTime.parse(json['reviewedAt'] as String),
  durationMs: (json['durationMs'] as num?)?.toInt(),
  undone: json['undone'] as bool?,
);

Map<String, dynamic> _$ReviewLogToJson(ReviewLog instance) => <String, dynamic>{
  'id': instance.id,
  'flashcardId': instance.flashcardId,
  'rating': _$ReviewLogRatingEnumMap[instance.rating]!,
  'stateBefore': instance.stateBefore,
  'stateAfter': instance.stateAfter,
  'reviewedAt': instance.reviewedAt.toIso8601String(),
  'durationMs': ?instance.durationMs,
  'undone': ?instance.undone,
};

const _$ReviewLogRatingEnumMap = {
  ReviewLogRating.again: 'again',
  ReviewLogRating.good: 'good',
  ReviewLogRating.easy: 'easy',
};
