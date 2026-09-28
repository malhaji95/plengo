// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stats_trend.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StatsTrend _$StatsTrendFromJson(Map<String, dynamic> json) => StatsTrend(
  weeks: (json['weeks'] as List<dynamic>).map((e) => TrendWeek.fromJson(e as Map<String, dynamic>)).toList(),
);

Map<String, dynamic> _$StatsTrendToJson(StatsTrend instance) => <String, dynamic>{'weeks': instance.weeks};
