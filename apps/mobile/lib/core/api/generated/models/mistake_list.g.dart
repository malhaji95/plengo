// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'mistake_list.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MistakeList _$MistakeListFromJson(Map<String, dynamic> json) => MistakeList(
  items: (json['items'] as List<dynamic>)
      .map((e) => Mistake.fromJson(e as Map<String, dynamic>))
      .toList(),
  activeCount: (json['activeCount'] as num).toInt(),
  masteredCount: (json['masteredCount'] as num).toInt(),
  masteryStreak: (json['masteryStreak'] as num).toInt(),
  nextCursor: json['nextCursor'] as String?,
);

Map<String, dynamic> _$MistakeListToJson(MistakeList instance) =>
    <String, dynamic>{
      'items': instance.items,
      'activeCount': instance.activeCount,
      'masteredCount': instance.masteredCount,
      'masteryStreak': instance.masteryStreak,
      'nextCursor': instance.nextCursor,
    };
