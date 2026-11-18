// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'redemption_status_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RedemptionStatusRequest _$RedemptionStatusRequestFromJson(
  Map<String, dynamic> json,
) => RedemptionStatusRequest(
  status: $enumDecode(_$RedemptionStatusRequestStatusEnumMap, json['status']),
  note: json['note'] as String?,
);

Map<String, dynamic> _$RedemptionStatusRequestToJson(
  RedemptionStatusRequest instance,
) => <String, dynamic>{'status': instance.status, 'note': ?instance.note};

const _$RedemptionStatusRequestStatusEnumMap = {
  RedemptionStatusRequestStatus.fulfilled: 'fulfilled',
  RedemptionStatusRequestStatus.cancelled: 'cancelled',
};
