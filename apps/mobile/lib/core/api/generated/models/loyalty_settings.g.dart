// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoyaltySettings _$LoyaltySettingsFromJson(Map<String, dynamic> json) =>
    LoyaltySettings(
      enabled: json['enabled'] as bool,
      pointsPerReview: (json['pointsPerReview'] as num).toInt(),
      dailyCap: (json['dailyCap'] as num).toInt(),
      pointsPerCorrectQuestion: (json['pointsPerCorrectQuestion'] as num)
          .toInt(),
    );

Map<String, dynamic> _$LoyaltySettingsToJson(LoyaltySettings instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'pointsPerReview': instance.pointsPerReview,
      'dailyCap': instance.dailyCap,
      'pointsPerCorrectQuestion': instance.pointsPerCorrectQuestion,
    };
