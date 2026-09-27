// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'due_card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DueCard _$DueCardFromJson(Map<String, dynamic> json) => DueCard(
  card: StudentCard.fromJson(json['card'] as Map<String, dynamic>),
  deckTitleAr: json['deckTitleAr'] as String,
  subjectId: json['subjectId'] as String,
  subjectNameAr: json['subjectNameAr'] as String,
  state: SrsCardState.fromJson(json['state'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DueCardToJson(DueCard instance) => <String, dynamic>{
  'card': instance.card,
  'deckTitleAr': instance.deckTitleAr,
  'subjectId': instance.subjectId,
  'subjectNameAr': instance.subjectNameAr,
  'state': instance.state,
};
