// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'srs_card_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SrsCardState _$SrsCardStateFromJson(Map<String, dynamic> json) => SrsCardState(
  state: $enumDecode(_$SrsCardStateStateEnumMap, json['state']),
  step: (json['step'] as num).toInt(),
  dueAt: DateTime.parse(json['dueAt'] as String),
  intervalDays: (json['intervalDays'] as num).toInt(),
  ease: json['ease'] as num,
  reps: (json['reps'] as num).toInt(),
  lapses: (json['lapses'] as num).toInt(),
  lastReviewedAt: json['lastReviewedAt'] == null
      ? null
      : DateTime.parse(json['lastReviewedAt'] as String),
  flashcardId: json['flashcardId'] as String,
  updatedAt: json['updatedAt'] as String,
);

Map<String, dynamic> _$SrsCardStateToJson(SrsCardState instance) =>
    <String, dynamic>{
      'state': _$SrsCardStateStateEnumMap[instance.state]!,
      'step': instance.step,
      'dueAt': instance.dueAt.toIso8601String(),
      'intervalDays': instance.intervalDays,
      'ease': instance.ease,
      'reps': instance.reps,
      'lapses': instance.lapses,
      'lastReviewedAt': instance.lastReviewedAt?.toIso8601String(),
      'flashcardId': instance.flashcardId,
      'updatedAt': instance.updatedAt,
    };

const _$SrsCardStateStateEnumMap = {
  SrsCardStateState.valueNew: 'new',
  SrsCardStateState.learning: 'learning',
  SrsCardStateState.review: 'review',
  SrsCardStateState.relearning: 'relearning',
};
