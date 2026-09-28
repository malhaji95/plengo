import '../api/api_exception.dart';
import '../api/generated/export.dart';
import '../content/flashcard_repository.dart';
import '../content/question_repository.dart';
import '../content/study_card.dart';
import 'offline_content.dart';

bool _offline(Object e) => e is ApiException && e.code == 'NETWORK_ERROR';

/// Questions with downloaded packs behind them (spec §22.6): a question held in a pack is graded
/// on the device, online or offline; lists fall back to pack questions without a connection.
class OfflineQuestionRepository extends QuestionRepository {
  OfflineQuestionRepository(super.client, this.content);

  final OfflineContent content;

  @override
  Future<CheckResult> check(String questionId, {String? selectedOptionId, String? writtenAnswer}) async {
    final pq = await content.question(questionId);
    if (pq != null && pq.canGradeLocally) {
      return gradeLocally(pq.question, selectedOptionId: selectedOptionId, writtenAnswer: writtenAnswer);
    }
    return super.check(questionId, selectedOptionId: selectedOptionId, writtenAnswer: writtenAnswer);
  }

  @override
  Future<StudentQuestionPage> page(QuestionQuery q, {String? cursor}) async {
    try {
      return await super.page(q, cursor: cursor);
    } catch (e) {
      if (!_offline(e) || cursor != null) rethrow;
      final local = await content.questions(
        subjectId: q.subjectId,
        teacherTrackId: q.teacherTrackId,
        unitId: q.unitId,
        lessonId: q.lessonId,
      );
      if (local.isEmpty) rethrow;
      return StudentQuestionPage(
        items: [
          for (final pq in local)
            StudentQuestion(
              id: pq.question.id,
              type: StudentQuestionType.values.firstWhere((t) => t.json == pq.question.type.json),
              subjectId: pq.question.subjectId,
              teacherTrackId: pq.question.teacherTrackId,
              unitId: pq.question.unitId,
              lessonId: pq.question.lessonId,
              sortOrder: pq.question.sortOrder,
              difficulty: pq.question.difficulty == null
                  ? null
                  : StudentQuestionDifficulty.values.firstWhere((d) => d.json == pq.question.difficulty!.json),
              isFree: pq.question.isFree,
              locked: false,
              questionText: pq.question.questionText,
              options: [for (final o in pq.question.options) StudentOption(id: o.id, text: o.text)],
            ),
        ],
        nextCursor: null,
        totalCount: local.length,
        accessibleCount: local.length,
      );
    }
  }
}

/// Official decks with downloaded packs behind them: a downloaded deck is read from the device
/// (Browse and Study work offline, §22.11).
class OfflineFlashcardRepository extends FlashcardRepository {
  OfflineFlashcardRepository(super.client, this.content);

  final OfflineContent content;

  static StudentDeck _deck(OfflineDeck d) => StudentDeck(
    id: d.id,
    subjectId: d.subjectId,
    teacherTrackId: d.teacherTrackId,
    unitId: d.unitId,
    lessonId: d.lessonId,
    titleAr: d.titleAr,
    description: d.description,
    coverUrl: null,
    cardCount: d.cardIds.length,
    isFree: d.isFree,
    locked: false,
    contentVersion: 0,
    sortOrder: d.sortOrder,
  );

  static CardImage _image(OfflineImage i) => CardImage(
    mediaId: i.mediaId,
    cacheKey: '${i.mediaId}:${i.version}',
    fullUrl: i.url,
    thumbUrl: i.url,
    width: i.width,
    height: i.height,
  );

  static StudentCard officialCard(OfflineCard c) => StudentCard(
    id: c.id,
    deckId: c.deckId,
    sortOrder: c.sortOrder,
    contentVersion: 0,
    front: _image(c.front),
    back: _image(c.back),
  );

  @override
  Future<StudentDeck> deck(String id) async {
    try {
      return await super.deck(id);
    } catch (e) {
      final local = _offline(e) ? await content.deck(id) : null;
      if (local == null) rethrow;
      return _deck(local);
    }
  }

  @override
  Future<DeckCards> deckCards(String id) async {
    try {
      return await super.deckCards(id);
    } catch (e) {
      final deck = _offline(e) ? await content.deck(id) : null;
      final cards = deck == null ? null : await content.cards(id);
      if (deck == null || cards == null) rethrow;
      return DeckCards(deck: _deck(deck), cards: [for (final c in cards) officialCard(c)], urlsExpireAt: '');
    }
  }

  /// A downloaded deck's cards with their decrypted images, or null when it is not downloaded.
  Future<List<StudyCard>?> localStudyCards(String deckId) async {
    final cards = await content.cards(deckId);
    if (cards == null || cards.isEmpty) return null;
    return [
      for (final c in cards)
        StudyCard(
          key: c.id,
          officialId: c.id,
          front: CardFaceView(image: _image(c.front), localImage: await content.image(c.front.mediaId)),
          back: CardFaceView(image: _image(c.back), localImage: await content.image(c.back.mediaId)),
        ),
    ];
  }
}
