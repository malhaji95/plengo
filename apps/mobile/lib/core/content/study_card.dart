import 'dart:convert';
import 'dart:typed_data';

import '../api/generated/export.dart';
import '../db/app_database.dart';
import '../srs/srs_key.dart';

/// One side of a card as the app shows it: text, an image, or both. `localImage` is a picked
/// image that has not reached the server yet.
class CardFaceView {
  const CardFaceView({this.text, this.image, this.localImage});

  final String? text;
  final CardImage? image;
  final Uint8List? localImage;

  bool get isEmpty => (text == null || text!.trim().isEmpty) && image == null && localImage == null;
}

/// A card in Browse or Study, official (images only, §13.1) or the student's own (§13.9). `key` is
/// the SRS key ([SrsKey]).
class StudyCard {
  const StudyCard({required this.key, required this.front, required this.back, this.officialId});

  factory StudyCard.official(StudentCard c) => StudyCard(
    key: c.id,
    officialId: c.id,
    front: CardFaceView(image: c.front),
    back: CardFaceView(image: c.back),
  );

  factory StudyCard.own(LocalCardRow r) => StudyCard(
    key: SrsKey.userCard(r.id),
    officialId: r.officialFlashcardId,
    front: CardFaceView(text: r.frontText, image: imageFromJson(r.frontImageJson), localImage: r.frontLocalImage),
    back: CardFaceView(text: r.backText, image: imageFromJson(r.backImageJson), localImage: r.backLocalImage),
  );

  final String key;
  final CardFaceView front;
  final CardFaceView back;

  /// The official card this shows (official cards and "أضف إلى بطاقاتي" references).
  final String? officialId;

  Iterable<CardImage> get images => [?front.image, ?back.image];

  static CardImage? imageFromJson(String? json) =>
      json == null ? null : CardImage.fromJson(jsonDecode(json) as Map<String, Object?>);
  static String? imageToJson(CardImage? image) => image == null ? null : jsonEncode(image.toJson());
}
