// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_error.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportError _$ImportErrorFromJson(Map<String, dynamic> json) => ImportError(
  rowNumber: (json['rowNumber'] as num).toInt(),
  field: json['field'] as String?,
  message: json['message'] as String,
);

Map<String, dynamic> _$ImportErrorToJson(ImportError instance) =>
    <String, dynamic>{
      'rowNumber': instance.rowNumber,
      'field': instance.field,
      'message': instance.message,
    };
