// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'by_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ByState _$ByStateFromJson(Map<String, dynamic> json) => ByState(
  newValue: (json['new'] as num).toInt(),
  learning: (json['learning'] as num).toInt(),
  review: (json['review'] as num).toInt(),
  relearning: (json['relearning'] as num).toInt(),
);

Map<String, dynamic> _$ByStateToJson(ByState instance) => <String, dynamic>{
  'new': instance.newValue,
  'learning': instance.learning,
  'review': instance.review,
  'relearning': instance.relearning,
};
