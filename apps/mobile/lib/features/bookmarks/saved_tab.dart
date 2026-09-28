import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../shared/text/bidi.dart';
import '../../shared/widgets/async_view.dart';
import '../flashcards/card_face.dart';
import '../questions/questions_screen.dart';
import 'bookmark_button.dart';
import 'bookmark_providers.dart';

const _filters = <BookmarkItemType?, String>{
  null: 'الكل',
  BookmarkItemType.question: 'الأسئلة',
  BookmarkItemType.deck: 'المجموعات',
  BookmarkItemType.flashcard: 'البطاقات',
};

/// The Saved tab (المحفوظات, spec §17). Items the student can no longer open show as locked.
class SavedTab extends ConsumerStatefulWidget {
  const SavedTab({super.key});

  @override
  ConsumerState<SavedTab> createState() => _SavedTabState();
}

class _SavedTabState extends ConsumerState<SavedTab> {
  BookmarkItemType? _type;

  @override
  Widget build(BuildContext context) {
    final list = ref.watch(bookmarksProvider);
    // Toggling elsewhere refreshes the list.
    ref.listen(bookmarkKeysProvider, (_, _) => ref.invalidate(bookmarksProvider));
    return Scaffold(
      appBar: AppBar(title: const Text('المحفوظات')),
      body: AsyncView(
        value: list,
        onRetry: () => ref.invalidate(bookmarksProvider),
        data: (l) {
          final items = l.items.where((b) => _type == null || b.itemType == _type).toList();
          return RefreshIndicator(
            onRefresh: () => ref.refresh(bookmarksProvider.future),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final MapEntry(key: t, value: label) in _filters.entries)
                          ChoiceChip(
                            label: Text(label),
                            selected: _type == t,
                            onSelected: (_) => setState(() => _type = t),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (items.isEmpty)
                      const EmptyState('احفظ الأسئلة والبطاقات لتعود إليها هنا', icon: Icons.bookmark_border),
                    for (final b in items) _BookmarkTile(bookmark: b),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BookmarkTile extends StatelessWidget {
  const _BookmarkTile({required this.bookmark});

  final Bookmark bookmark;

  @override
  Widget build(BuildContext context) {
    final b = bookmark;
    final scheme = Theme.of(context).colorScheme;
    final (IconData icon, String kind) = switch (b.itemType) {
      BookmarkItemType.question => (Icons.quiz_outlined, 'سؤال'),
      BookmarkItemType.deck => (Icons.style_outlined, 'مجموعة بطاقات'),
      _ => (Icons.crop_portrait, 'بطاقة'),
    };
    final title = !b.available
        ? 'لم يعد هذا العنصر متاحاً'
        : b.locked && b.itemType == BookmarkItemType.question
        ? 'سؤال مقفل'
        : b.titleAr ?? '';
    VoidCallback? onTap;
    if (b.available && !b.locked) {
      onTap = switch (b.itemType) {
        BookmarkItemType.question => () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PracticeScreen(title: 'سؤال محفوظ', questions: [b.question!]),
          ),
        ),
        BookmarkItemType.deck => () => context.go('${Routes.decks}/${b.itemId}'),
        BookmarkItemType.flashcard when b.card != null => () => showDialog<void>(
          context: context,
          builder: (_) => Dialog(child: _CardPreview(card: b.card!)),
        ),
        _ => null,
      };
    } else if (b.available && b.locked && b.itemType == BookmarkItemType.deck) {
      onTap = () => context.go('${Routes.decks}/${b.itemId}');
    }
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(isolateLtr(title), maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text([kind, if (b.subjectNameAr != null) b.subjectNameAr!].join(' · ')),
        onTap: onTap,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (b.locked) Icon(Icons.lock_outline, color: scheme.outline, semanticLabel: 'مقفل'),
            BookmarkButton(type: b.itemType, id: b.itemId),
          ],
        ),
      ),
    );
  }
}

class _CardPreview extends StatefulWidget {
  const _CardPreview({required this.card});

  final StudentCard card;

  @override
  State<_CardPreview> createState() => _CardPreviewState();
}

class _CardPreviewState extends State<_CardPreview> {
  bool _back = false;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(12),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 420),
          child: FlashcardView(card: widget.card, flipped: _back, onTap: () => setState(() => _back = !_back)),
        ),
        TextButton(onPressed: () => setState(() => _back = !_back), child: Text(_back ? 'الوجه' : 'اقلب')),
      ],
    ),
  );
}
