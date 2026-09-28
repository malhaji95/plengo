// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_count.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DayCount _$DayCountFromJson(Map<String, dynamic> json) => DayCount(
  date: json['date'] as String,
  count: (json['count'] as num).toInt(),
);

Map<String, dynamic> _$DayCountToJson(DayCount instance) => <String, dynamic>{
  'date': instance.date,
  'count': instance.count,
};
