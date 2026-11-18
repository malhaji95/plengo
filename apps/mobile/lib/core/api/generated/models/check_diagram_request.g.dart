// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_diagram_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CheckDiagramRequest _$CheckDiagramRequestFromJson(Map<String, dynamic> json) =>
    CheckDiagramRequest(
      answers: (json['answers'] as List<dynamic>)
          .map((e) => Answers.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CheckDiagramRequestToJson(
  CheckDiagramRequest instance,
) => <String, dynamic>{'answers': instance.answers};
