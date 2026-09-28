// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'srs_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SrsState _$SrsStateFromJson(Map<String, dynamic> json) => SrsState(
  state: $enumDecode(_$SrsStateStateEnumMap, json['state']),
  step: (json['step'] as num).toInt(),
  dueAt: DateTime.parse(json['dueAt'] as String),
  intervalDays: (json['intervalDays'] as num).toInt(),
  ease: json['ease'] as num,
  reps: (json['reps'] as num).toInt(),
  lapses: (json['lapses'] as num).toInt(),
  lastReviewedAt: json['lastReviewedAt'] == null ? null : DateTime.parse(json['lastReviewedAt'] as String),
);

Map<String, dynamic> _$SrsStateToJson(SrsState instance) => <String, dynamic>{
  'state': instance.state,
  'step': instance.step,
  'dueAt': instance.dueAt.toIso8601String(),
  'intervalDays': instance.intervalDays,
  'ease': instance.ease,
  'reps': instance.reps,
  'lapses': instance.lapses,
  'lastReviewedAt': instance.lastReviewedAt?.toIso8601String(),
};

const _$SrsStateStateEnumMap = {
  SrsStateState.valueNew: 'new',
  SrsStateState.learning: 'learning',
  SrsStateState.review: 'review',
  SrsStateState.relearning: 'relearning',
};
