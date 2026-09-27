// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subject_outline.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SubjectOutline _$SubjectOutlineFromJson(Map<String, dynamic> json) =>
    SubjectOutline(
      subject: Subject.fromJson(json['subject'] as Map<String, dynamic>),
      units: (json['units'] as List<dynamic>)
          .map((e) => UnitWithLessons.fromJson(e as Map<String, dynamic>))
          .toList(),
      lessons: (json['lessons'] as List<dynamic>)
          .map((e) => Lesson.fromJson(e as Map<String, dynamic>))
          .toList(),
      tracks: (json['tracks'] as List<dynamic>)
          .map((e) => SubjectTrack.fromJson(e as Map<String, dynamic>))
          .toList(),
      access: ScopeAccess.fromJson(json['access'] as Map<String, dynamic>),
      questionCount: ContentCount.fromJson(
        json['questionCount'] as Map<String, dynamic>,
      ),
    );

Map<String, dynamic> _$SubjectOutlineToJson(SubjectOutline instance) =>
    <String, dynamic>{
      'subject': instance.subject,
      'units': instance.units,
      'lessons': instance.lessons,
      'tracks': instance.tracks,
      'access': instance.access,
      'questionCount': instance.questionCount,
    };
