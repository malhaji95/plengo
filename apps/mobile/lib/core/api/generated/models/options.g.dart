// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'options.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Options _$OptionsFromJson(Map<String, dynamic> json) => Options(
  id: json['id'] as String,
  text: json['text'] as String,
  isCorrect: json['isCorrect'] as bool,
);

Map<String, dynamic> _$OptionsToJson(Options instance) => <String, dynamic>{
  'id': instance.id,
  'text': instance.text,
  'isCorrect': instance.isCorrect,
};
