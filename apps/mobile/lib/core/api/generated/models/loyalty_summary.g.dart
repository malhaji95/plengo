// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoyaltySummary _$LoyaltySummaryFromJson(Map<String, dynamic> json) =>
    LoyaltySummary(
      enabled: json['enabled'] as bool,
      balance: (json['balance'] as num).toInt(),
      earnedToday: (json['earnedToday'] as num).toInt(),
      dailyCap: (json['dailyCap'] as num).toInt(),
      remainingToday: (json['remainingToday'] as num?)?.toInt(),
      day: json['day'] as String,
      rules: LoyaltySettings.fromJson(json['rules'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$LoyaltySummaryToJson(LoyaltySummary instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'balance': instance.balance,
      'earnedToday': instance.earnedToday,
      'dailyCap': instance.dailyCap,
      'remainingToday': instance.remainingToday,
      'day': instance.day,
      'rules': instance.rules,
    };
