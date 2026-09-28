// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offline_pack.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OfflinePack _$OfflinePackFromJson(Map<String, dynamic> json) => OfflinePack(
  packKey: json['packKey'] as String,
  kind: $enumDecode(_$OfflinePackKindEnumMap, json['kind']),
  unitId: json['unitId'] as String?,
  deckId: json['deckId'] as String?,
  titleAr: json['titleAr'] as String,
  itemCount: (json['itemCount'] as num).toInt(),
  sizeBytes: (json['sizeBytes'] as num).toInt(),
  version: json['version'] as String,
  premium: json['premium'] as bool,
);

Map<String, dynamic> _$OfflinePackToJson(OfflinePack instance) =>
    <String, dynamic>{
      'packKey': instance.packKey,
      'kind': instance.kind,
      'unitId': instance.unitId,
      'deckId': instance.deckId,
      'titleAr': instance.titleAr,
      'itemCount': instance.itemCount,
      'sizeBytes': instance.sizeBytes,
      'version': instance.version,
      'premium': instance.premium,
    };

const _$OfflinePackKindEnumMap = {
  OfflinePackKind.questions: 'questions',
  OfflinePackKind.decks: 'decks',
  OfflinePackKind.quizzes: 'quizzes',
  OfflinePackKind.deck: 'deck',
};
