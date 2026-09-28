// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'attempt_option.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AttemptOption _$AttemptOptionFromJson(Map<String, dynamic> json) =>
    AttemptOption(
      id: json['id'] as String,
      text: json['text'] as String,
      isCorrect: json['isCorrect'] as bool?,
    );

Map<String, dynamic> _$AttemptOptionToJson(AttemptOption instance) =>
    <String, dynamic>{
      'id': instance.id,
      'text': instance.text,
      'isCorrect': instance.isCorrect,
    };
