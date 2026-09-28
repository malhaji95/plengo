// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:json_annotation/json_annotation.dart';

import 'exam_countdown.dart';
import 'free_subject.dart';
import 'home_banner.dart';
import 'my_entitlement.dart';
import 'resume_item.dart';
import 'teacher.dart';
import 'today.dart';

part 'home.g.dart';

@JsonSerializable()
class Home {
  const Home({
    required this.greetingName,
    required this.unreadNotifications,
    required this.countdown,
    required this.banners,
    required this.today,
    required this.resume,
    required this.myAccess,
    required this.freeSubjects,
    required this.followedTeachers,
    required this.activeMistakes,
  });
  
  factory Home.fromJson(Map<String, Object?> json) => _$HomeFromJson(json);
  
  final String greetingName;
  final int unreadNotifications;
  @JsonKey(includeIfNull: true)
  final ExamCountdown? countdown;
  final List<HomeBanner> banners;
  final Today today;
  final List<ResumeItem> resume;
  final List<MyEntitlement> myAccess;
  final List<FreeSubject> freeSubjects;
  final List<Teacher> followedTeachers;
  final int activeMistakes;

  Map<String, Object?> toJson() => _$HomeToJson(this);
}
