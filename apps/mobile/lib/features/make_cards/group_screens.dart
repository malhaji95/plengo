import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../core/content/study_card.dart';
import '../../core/db/app_database.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/responsive.dart';
import '../flashcards/card_face.dart';
import '../flashcards/decks_screen.dart' show cardCountLabel;
import '../flashcards/flashcard_ui.dart';
import '../my_decks/my_decks_providers.dart';
import 'card_templates.dart';
import 'make_cards_providers.dart';
import 'make_cards_screen.dart' show groupLocation;
import 'make_cards_widgets.dart';

/// The group's cards as Browse and Study show them (on the group's frame).
List<StudyCard> groupCards(LocalDeckRow deck, List<LocalCardRow> rows) => [
  for (final r in rows)
    if (!r.locked) StudyCard.own(r, templateKey: deck.templateKey),
];

/// Builds [body] for a group that still exists; a deleted or unknown group says so.
class _GroupFrame extends ConsumerWidget {
  const _GroupFrame({required this.deckId, required this.title, required this.body});

  final String deckId;
  final String Function(LocalDeckRow deck)? title;
  final Widget Function(LocalDeckRow deck, List<LocalCardRow> cards) body;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deck = ref.watch(myDeckProvider(deckId));
    final cards = ref.watch(myDeckCardsProvider(deckId));
    final d = deck.value;
    return Scaffold(
      appBar: plengoAppBar(context, title: d == null ? null : title?.call(d)),
      body: ContentWidth(
        child: AsyncView(
          value: deck,
          onRetry: () => ref.invalidate(myDeckProvider(deckId)),
          data: (d) => d == null
              ? const EmptyState('لم تعد هذه المجموعة موجودة')
              : AsyncView(
                  value: cards,
                  onRetry: () => ref.invalidate(myDeckCardsProvider(deckId)),
                  data: (rows) => body(d, rows),
                ),
        ),
      ),
    );
  }
}

/// The group's name, subject and card count on a soft card in its hue.
class _GroupSummary extends ConsumerWidget {
  const _GroupSummary({required this.deck, required this.count});

  final LocalDeckRow deck;
  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.surface;
    final hue = groupHue(deck);
    final subjects = ref.watch(studentSubjectsProvider).value ?? const [];
    return PlengoCard(
      color: s.isDark ? Color.alphaBlend(hue.base.withValues(alpha: 0.12), s.card) : hue.soft,
      child: Row(
        children: [
          SubjectIconTile(icon: Icons.style_rounded, hue: hue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Semantics(
                  header: true,
                  child: Text(deck.name, style: PlengoType.section.copyWith(color: s.ink)),
                ),
                Text(
                  '${subjectNameOf(subjects, deck.subjectId)} · ${cardCountLabel(count)}',
                  key: const Key('group.summary'),
                  style: PlengoType.caption.copyWith(color: s.isDark ? s.mute : hue.ink),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A group's page (v3 §7): its summary, a preview carousel of the cards on their frame, «إضافة
/// بطاقات», «تعديل المجموعة», then مراجعة المجموعة · عرض البطاقات · إعدادات المجموعة · إحصائيات
/// التقدم.
class GroupScreen extends StatelessWidget {
  const GroupScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context) => _GroupFrame(
    deckId: deckId,
    title: (_) => 'مجموعاتي',
    body: (deck, rows) {
      final cards = groupCards(deck, rows);
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
        children: [
          _GroupSummary(deck: deck, count: cards.length),
          const SectionHeader('معاينة البطاقات'),
          if (cards.isEmpty)
            Text('لا بطاقات بعد', style: PlengoType.sub.copyWith(color: context.surface.mute))
          else
            _PreviewCarousel(cards: cards),
          const SizedBox(height: 16),
          PlengoButton(
            key: const Key('groupPage.add'),
            label: 'إضافة بطاقات',
            icon: Icons.add_rounded,
            onPressed: () => context.push(groupLocation(deckId, 'add')),
          ),
          const SizedBox(height: 10),
          PlengoButton(
            key: const Key('groupPage.edit'),
            label: 'تعديل المجموعة',
            icon: Icons.edit_rounded,
            variant: PlengoButtonVariant.secondary,
            onPressed: () => context.push(groupLocation(deckId, 'edit')),
          ),
          const SizedBox(height: 16),
          PlengoCard(
            padding: const EdgeInsetsDirectional.symmetric(vertical: 4),
            child: Column(
              children: [
                ListRow(
                  flat: true,
                  icon: Icons.play_arrow_rounded,
                  hue: PlengoColors.blue,
                  title: 'مراجعة المجموعة',
                  caption: 'ابدأ المراجعة باستخدام التكرار المتباعد',
                  onTap: cards.isEmpty ? null : () => context.push('${Routes.myDeckStudy}/$deckId/study'),
                ),
                ListRow(
                  flat: true,
                  icon: Icons.style_outlined,
                  hue: PlengoColors.green,
                  title: 'عرض البطاقات',
                  caption: 'تصفّح جميع البطاقات (${cards.length})',
                  onTap: cards.isEmpty ? null : () => context.push('${Routes.myDeckStudy}/$deckId/browse'),
                ),
                ListRow(
                  key: const Key('groupPage.settings'),
                  flat: true,
                  icon: Icons.settings_rounded,
                  hue: PlengoColors.orange,
                  title: 'إعدادات المجموعة',
                  caption: 'الاسم والمادة والقالب',
                  onTap: () => context.push(groupLocation(deckId, 'settings')),
                ),
                ListRow(
                  key: const Key('groupPage.stats'),
                  flat: true,
                  showDivider: false,
                  icon: Icons.bar_chart_rounded,
                  hue: PlengoColors.pink,
                  title: 'إحصائيات التقدم',
                  caption: 'ما تعلّمته من بطاقات المجموعة',
                  onTap: () => showGroupStats(context, deckId),
                ),
              ],
            ),
          ),
        ],
      );
    },
  );
}

/// One card at a time on its frame, «1 / N» and the arrows; a tap flips it.
class _PreviewCarousel extends StatefulWidget {
  const _PreviewCarousel({required this.cards});

  final List<StudyCard> cards;

  @override
  State<_PreviewCarousel> createState() => _PreviewCarouselState();
}

class _PreviewCarouselState extends State<_PreviewCarousel> {
  int _index = 0;
  bool _flipped = false;

  void _go(int delta) => setState(() {
    _index = (_index + delta).clamp(0, widget.cards.length - 1);
    _flipped = false;
  });

  @override
  Widget build(BuildContext context) {
    final cards = widget.cards;
    _index = _index.clamp(0, cards.length - 1);
    final s = context.surface;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PlengoIconButton(
              icon: Icons.chevron_right_rounded,
              tooltip: 'البطاقة السابقة',
              onPressed: _index > 0 ? () => _go(-1) : null,
            ),
            const SizedBox(width: 12),
            Text(
              '${_index + 1} / ${cards.length}',
              key: const Key('preview.position'),
              textDirection: TextDirection.ltr,
              style: PlengoType.rowTitle.copyWith(color: s.ink),
            ),
            const SizedBox(width: 12),
            PlengoIconButton(
              icon: Icons.chevron_left_rounded,
              tooltip: 'البطاقة التالية',
              onPressed: _index < cards.length - 1 ? () => _go(1) : null,
            ),
          ],
        ),
        const SizedBox(height: 10),
        FlashcardView(
          card: cards[_index],
          flipped: _flipped,
          maxHeight: 320,
          onTap: () => setState(() => _flipped = !_flipped),
        ),
        const SizedBox(height: 6),
        Text(
          _flipped ? 'الوجه الخلفي · اضغط للقلب' : 'الوجه الأمامي · اضغط للقلب',
          style: PlengoType.caption.copyWith(color: s.mute),
        ),
      ],
    );
  }
}

/// إحصائيات التقدم: the group's cards by SRS bucket and how many are mastered, on this device.
Future<void> showGroupStats(BuildContext context, String deckId) => showPlengoSheet<void>(
  context: context,
  title: 'إحصائيات التقدم',
  builder: (_) => _GroupStats(deckId: deckId),
);

class _GroupStats extends ConsumerWidget {
  const _GroupStats({required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(groupStatsProvider(deckId));
    final s = context.surface;
    return AsyncView(
      value: stats,
      onRetry: () => ref.invalidate(groupStatsProvider(deckId)),
      data: (st) {
        final started = st.total - st.fresh;
        return Column(
          key: const Key('group.stats'),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PlengoProgressBar(
              value: st.total == 0 ? 0 : started / st.total,
              label: st.total == 0 ? 'لا بطاقات بعد' : 'بدأت ${cardCountLabel(started)} من ${st.total}',
              semanticsLabel: 'تقدّم المجموعة',
            ),
            const SizedBox(height: 12),
            BucketChips(fresh: st.fresh, learning: st.learning, review: st.review),
            const SizedBox(height: 10),
            Text('مُتقنة: ${st.mastered}', style: PlengoType.sub.copyWith(color: s.mute)),
          ],
        );
      },
    );
  }
}

/// تعديل المجموعة (v3 §7): تعديل البطاقات · إضافة بطاقات · حذف المجموعة (after a confirm sheet).
class EditGroupScreen extends ConsumerWidget {
  const EditGroupScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _GroupFrame(
    deckId: deckId,
    title: (_) => 'تعديل المجموعة',
    body: (deck, rows) => ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        _GroupSummary(deck: deck, count: rows.length),
        const SizedBox(height: 16),
        ListRow(
          key: const Key('editGroup.cards'),
          icon: Icons.edit_rounded,
          hue: PlengoColors.blue,
          title: 'تعديل البطاقات',
          onTap: () => context.push(groupLocation(deckId, 'cards')),
        ),
        const SizedBox(height: PlengoSpace.listGap),
        ListRow(
          key: const Key('editGroup.add'),
          icon: Icons.add_rounded,
          hue: PlengoColors.green,
          title: 'إضافة بطاقات',
          onTap: () => context.push(groupLocation(deckId, 'add')),
        ),
        const SizedBox(height: PlengoSpace.listGap),
        ListRow(
          key: const Key('editGroup.delete'),
          icon: Icons.delete_outline_rounded,
          hue: PlengoColors.red,
          title: 'حذف المجموعة',
          onTap: () => _delete(context, ref, deck),
        ),
      ],
    ),
  );

  Future<void> _delete(BuildContext context, WidgetRef ref, LocalDeckRow deck) async {
    final ok = await showConfirmSheet(
      context,
      title: 'حذف «${deck.name}»؟',
      message: 'ستُحذف المجموعة وكل بطاقاتها من كل أجهزتك.',
      icon: Icons.delete_outline_rounded,
      hue: PlengoColors.red,
      primaryLabel: 'حذف المجموعة',
      primaryVariant: PlengoButtonVariant.danger,
      secondaryLabel: 'إلغاء',
    );
    if (ok != true || !context.mounted) return;
    await ref.read(myDecksStoreProvider).deleteDeck(deck.id);
    ref.read(myDecksSyncProvider).schedule();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حُذفت المجموعة')));
    context.go(Uri(path: Routes.makeCardsGroups, queryParameters: {'subjectId': ?deck.subjectId}).toString());
  }
}

/// تعديل البطاقات: each card with edit (the card editor) and delete.
class GroupCardsScreen extends ConsumerWidget {
  const GroupCardsScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _GroupFrame(
    deckId: deckId,
    title: (_) => 'تعديل البطاقات',
    body: (deck, rows) => rows.isEmpty
        ? const EmptyState('لا بطاقات في هذه المجموعة')
        : ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            children: [
              for (final (i, c) in rows.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: PlengoSpace.listGap),
                  child: ActionRow(
                    key: Key('groupCard.${c.id}'),
                    title: c.frontText ?? (c.officialFlashcardId != null ? 'بطاقة من بلينغو' : 'صورة'),
                    caption: c.backText,
                    leading: Container(
                      width: 32,
                      height: 32,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: PlengoColors.blue.soft, borderRadius: BorderRadius.circular(10)),
                      child: Text('${i + 1}', style: PlengoType.chip.copyWith(color: PlengoColors.blue.ink)),
                    ),
                    onTap: c.officialFlashcardId != null
                        ? null
                        : () => context.push(groupLocation(deckId, 'cards/${c.id}')),
                    trailing: [
                      IconButton(
                        key: Key('groupCard.${c.id}.delete'),
                        tooltip: 'حذف البطاقة',
                        icon: const Icon(Icons.delete_outline_rounded),
                        onPressed: () async {
                          final ok = await showConfirmSheet(
                            context,
                            title: 'حذف البطاقة؟',
                            icon: Icons.delete_outline_rounded,
                            hue: PlengoColors.red,
                            primaryLabel: 'حذف',
                            primaryVariant: PlengoButtonVariant.danger,
                            secondaryLabel: 'إلغاء',
                          );
                          if (ok != true) return;
                          await ref.read(myDecksStoreProvider).deleteCard(c.id);
                          ref.read(myDecksSyncProvider).schedule();
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
  );
}

/// إعدادات المجموعة: its name, subject and frame.
class GroupSettingsScreen extends ConsumerWidget {
  const GroupSettingsScreen({super.key, required this.deckId});

  final String deckId;

  @override
  Widget build(BuildContext context, WidgetRef ref) => _GroupFrame(
    deckId: deckId,
    title: (_) => 'إعدادات المجموعة',
    body: (deck, _) => _SettingsForm(deck: deck),
  );
}

class _SettingsForm extends ConsumerStatefulWidget {
  const _SettingsForm({required this.deck});

  final LocalDeckRow deck;

  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late final _name = TextEditingController(text: widget.deck.name);
  late String? _subjectId = widget.deck.subjectId;
  late String _templateKey = widget.deck.templateKey ?? CardTemplates.grid.key;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final d = widget.deck;
    await ref
        .read(myDecksStoreProvider)
        .saveDeck(
          id: d.id,
          name: _name.text,
          subjectId: _subjectId,
          color: _subjectId == d.subjectId || _subjectId == null ? d.color : hueHex(subjectHue(_subjectId!)),
          templateKey: _templateKey,
        );
    ref.read(myDecksSyncProvider).schedule();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('حُفظت الإعدادات')));
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final subjects = ref.watch(studentSubjectsProvider).value ?? const <CatalogSubject>[];
    final valid = _name.text.trim().isNotEmpty;
    return ListView(
      padding: const EdgeInsetsDirectional.only(top: 4, bottom: 28),
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.symmetric(horizontal: PlengoSpace.screen),
          child: TextField(
            key: const Key('settings.name'),
            controller: _name,
            maxLength: 100,
            decoration: const InputDecoration(labelText: 'اسم المجموعة'),
            onChanged: (_) => setState(() {}),
          ),
        ),
        if (subjects.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsetsDirectional.symmetric(horizontal: PlengoSpace.screen),
            child: SectionHeader('المادة', top: 8),
          ),
          SubjectCarousel(
            subjects: subjects,
            selected: _subjectId,
            onSelected: (id) => setState(() => _subjectId = id),
          ),
        ],
        const Padding(
          padding: EdgeInsetsDirectional.symmetric(horizontal: PlengoSpace.screen),
          child: SectionHeader('القالب'),
        ),
        TemplatePicker(
          templates: [
            ...availableTemplates(ref),
            // A frame this build does not offer stays selectable for the group that has it.
            if (!availableTemplates(ref).any((t) => t.key == _templateKey)) CardTemplates.of(_templateKey)!,
          ],
          selected: _templateKey,
          onSelected: (k) => setState(() => _templateKey = k),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 20, PlengoSpace.screen, 0),
          child: PlengoButton(key: const Key('settings.save'), label: 'حفظ', onPressed: valid ? _save : null),
        ),
        if (!valid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'اكتب اسم المجموعة',
              textAlign: TextAlign.center,
              style: PlengoType.caption.copyWith(color: s.mute),
            ),
          ),
      ],
    );
  }
}
