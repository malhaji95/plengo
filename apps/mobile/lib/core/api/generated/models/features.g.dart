// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'features.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Features _$FeaturesFromJson(Map<String, dynamic> json) => Features(
  teacherFollowing: json['teacherFollowing'] as bool,
  randomPractice: json['randomPractice'] as bool,
  studentDecks: json['studentDecks'] as bool,
  streaks: json['streaks'] as bool,
  contentReports: json['contentReports'] as bool,
);

Map<String, dynamic> _$FeaturesToJson(Features instance) => <String, dynamic>{
  'teacherFollowing': instance.teacherFollowing,
  'randomPractice': instance.randomPractice,
  'studentDecks': instance.studentDecks,
  'streaks': instance.streaks,
  'contentReports': instance.contentReports,
};
