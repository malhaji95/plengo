import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/content/flashcard_repository.dart';
import '../../shared/widgets/async_view.dart';
import '../subjects/catalog_providers.dart';
import '../teachers/teacher_providers.dart';
import 'flashcard_providers.dart';

/// Arabic count agreement: بطاقة واحدة، بطاقتان، 3–10 بطاقات، 11+ بطاقة.
String cardCountLabel(int n) => switch (n) {
  0 => 'لا بطاقات بعد',
  1 => 'بطاقة واحدة',
  2 => 'بطاقتان',
  >= 3 && <= 10 => '$n بطاقات',
  _ => '$n بطاقة',
};

/// Official decks of a subject's general content or of a track (spec §13.1). Locked decks show as
/// metadata only (§8.6).
class DecksScreen extends ConsumerWidget {
  const DecksScreen({super.key, required this.query, required this.title});

  final DeckQuery query;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final decks = ref.watch(decksProvider(query));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: AsyncView(
        value: decks,
        onRetry: () => ref.invalidate(decksProvider(query)),
        data: (list) => list.isEmpty
            ? const EmptyState('لا توجد بطاقات هنا بعد', icon: Icons.style_outlined)
            : Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      for (final d in list)
                        Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.style_outlined),
                            title: Text(d.titleAr),
                            subtitle: Text([cardCountLabel(d.cardCount), if (d.isFree) 'مجانية'].join(' · ')),
                            trailing: Icon(
                              d.locked ? Icons.lock_outline : Icons.chevron_left,
                              semanticLabel: d.locked ? 'مقفل' : null,
                            ),
                            onTap: () => context.go('${Routes.decks}/${d.id}'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

/// `/subjects/:id/decks`.
class SubjectDecksRoute extends ConsumerWidget {
  const SubjectDecksRoute({super.key, required this.subjectId});

  final String subjectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final outline = ref.watch(subjectOutlineProvider(subjectId)).value;
    return DecksScreen(
      query: (subjectId: subjectId, teacherTrackId: null, unitId: null, lessonId: null),
      title: outline != null ? 'بطاقات ${outline.subject.nameAr}' : 'البطاقات التعليمية',
    );
  }
}

/// `/tracks/:id/decks`.
class TrackDecksRoute extends ConsumerWidget {
  const TrackDecksRoute({super.key, required this.trackId});

  final String trackId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(trackProvider(trackId));
    return detail.when(
      data: (d) => DecksScreen(
        query: (subjectId: d.subject.id, teacherTrackId: trackId, unitId: null, lessonId: null),
        title: 'بطاقات ${d.track.titleAr}',
      ),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, _) => Scaffold(
        appBar: AppBar(),
        body: AsyncView(
          value: detail,
          onRetry: () => ref.invalidate(trackProvider(trackId)),
          data: (_) => const SizedBox(),
        ),
      ),
    );
  }
}
