// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'srs_sync_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SrsSyncState _$SrsSyncStateFromJson(Map<String, dynamic> json) => SrsSyncState(
  state: $enumDecode(_$SrsSyncStateStateEnumMap, json['state']),
  step: (json['step'] as num).toInt(),
  dueAt: DateTime.parse(json['dueAt'] as String),
  intervalDays: (json['intervalDays'] as num).toInt(),
  ease: json['ease'] as num,
  reps: (json['reps'] as num).toInt(),
  lapses: (json['lapses'] as num).toInt(),
  lastReviewedAt: json['lastReviewedAt'] == null ? null : DateTime.parse(json['lastReviewedAt'] as String),
  flashcardId: json['flashcardId'] as String?,
  userCardId: json['userCardId'] as String?,
);

Map<String, dynamic> _$SrsSyncStateToJson(SrsSyncState instance) => <String, dynamic>{
  'state': instance.state,
  'step': instance.step,
  'dueAt': instance.dueAt.toIso8601String(),
  'intervalDays': instance.intervalDays,
  'ease': instance.ease,
  'reps': instance.reps,
  'lapses': instance.lapses,
  'lastReviewedAt': instance.lastReviewedAt?.toIso8601String(),
  'flashcardId': ?instance.flashcardId,
  'userCardId': ?instance.userCardId,
};

const _$SrsSyncStateStateEnumMap = {
  SrsSyncStateState.valueNew: 'new',
  SrsSyncStateState.learning: 'learning',
  SrsSyncStateState.review: 'review',
  SrsSyncStateState.relearning: 'relearning',
};
