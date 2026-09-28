// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Home _$HomeFromJson(Map<String, dynamic> json) => Home(
  greetingName: json['greetingName'] as String,
  unreadNotifications: (json['unreadNotifications'] as num).toInt(),
  countdown: json['countdown'] == null
      ? null
      : ExamCountdown.fromJson(json['countdown'] as Map<String, dynamic>),
  banners: (json['banners'] as List<dynamic>)
      .map((e) => HomeBanner.fromJson(e as Map<String, dynamic>))
      .toList(),
  today: Today.fromJson(json['today'] as Map<String, dynamic>),
  resume: (json['resume'] as List<dynamic>)
      .map((e) => ResumeItem.fromJson(e as Map<String, dynamic>))
      .toList(),
  myAccess: (json['myAccess'] as List<dynamic>)
      .map((e) => MyEntitlement.fromJson(e as Map<String, dynamic>))
      .toList(),
  freeSubjects: (json['freeSubjects'] as List<dynamic>)
      .map((e) => FreeSubject.fromJson(e as Map<String, dynamic>))
      .toList(),
  followedTeachers: (json['followedTeachers'] as List<dynamic>)
      .map((e) => Teacher.fromJson(e as Map<String, dynamic>))
      .toList(),
  activeMistakes: (json['activeMistakes'] as num).toInt(),
);

Map<String, dynamic> _$HomeToJson(Home instance) => <String, dynamic>{
  'greetingName': instance.greetingName,
  'unreadNotifications': instance.unreadNotifications,
  'countdown': instance.countdown,
  'banners': instance.banners,
  'today': instance.today,
  'resume': instance.resume,
  'myAccess': instance.myAccess,
  'freeSubjects': instance.freeSubjects,
  'followedTeachers': instance.followedTeachers,
  'activeMistakes': instance.activeMistakes,
};
