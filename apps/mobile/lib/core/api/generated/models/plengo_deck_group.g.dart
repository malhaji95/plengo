// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plengo_deck_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlengoDeckGroup _$PlengoDeckGroupFromJson(Map<String, dynamic> json) =>
    PlengoDeckGroup(
      subjectId: json['subjectId'] as String,
      subjectNameAr: json['subjectNameAr'] as String,
      subjectCode: json['subjectCode'] as String,
      subjectCoverUrl: json['subjectCoverUrl'] as String?,
      subjectSortOrder: (json['subjectSortOrder'] as num).toInt(),
      decks: (json['decks'] as List<dynamic>)
          .map((e) => StudentDeck.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PlengoDeckGroupToJson(PlengoDeckGroup instance) =>
    <String, dynamic>{
      'subjectId': instance.subjectId,
      'subjectNameAr': instance.subjectNameAr,
      'subjectCode': instance.subjectCode,
      'subjectCoverUrl': instance.subjectCoverUrl,
      'subjectSortOrder': instance.subjectSortOrder,
      'decks': instance.decks,
    };
