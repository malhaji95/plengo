// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookmarkGroup _$BookmarkGroupFromJson(Map<String, dynamic> json) =>
    BookmarkGroup(
      subjectId: json['subjectId'] as String?,
      subjectNameAr: json['subjectNameAr'] as String?,
      unitId: json['unitId'] as String?,
      unitTitleAr: json['unitTitleAr'] as String?,
      lessonId: json['lessonId'] as String?,
      lessonTitleAr: json['lessonTitleAr'] as String?,
      deckId: json['deckId'] as String?,
      deckTitle: json['deckTitle'] as String?,
      ownDeck: json['ownDeck'] as bool,
    );

Map<String, dynamic> _$BookmarkGroupToJson(BookmarkGroup instance) =>
    <String, dynamic>{
      'subjectId': instance.subjectId,
      'subjectNameAr': instance.subjectNameAr,
      'unitId': instance.unitId,
      'unitTitleAr': instance.unitTitleAr,
      'lessonId': instance.lessonId,
      'lessonTitleAr': instance.lessonTitleAr,
      'deckId': instance.deckId,
      'deckTitle': instance.deckTitle,
      'ownDeck': instance.ownDeck,
    };
