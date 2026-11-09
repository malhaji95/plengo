import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/content/my_decks_store.dart';
import '../../core/db/app_database.dart';
import '../../shared/ui/ui.dart';
import '../../shared/util/uuid.dart';
import '../../shared/widgets/async_view.dart';
import '../flashcards/decks_screen.dart';
import '../flashcards/flashcard_ui.dart';
import 'my_decks_providers.dart';

/// Spoken names of the six hues.
const deckColorNames = {
  'yellow': 'أصفر',
  'blue': 'أزرق',
  'green': 'أخضر',
  'red': 'أحمر',
  'orange': 'برتقالي',
  'pink': 'زهري',
};

String _hex(Color c) => '#${(c.toARGB32() & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

/// Colours offered before the redesign, drawn as the nearest of the six hues.
const _legacyHues = {
  '#1E88E5': 'blue',
  '#43A047': 'green',
  '#F4511E': 'orange',
  '#8E24AA': 'pink',
  '#FDD835': 'yellow',
  '#546E7A': 'blue',
};

/// The hue a deck is drawn in: its stored colour when it is one of the six (or an older choice),
/// otherwise a stable hue from its id.
PlengoHue deckHue(String? hex, String id) {
  final h = hex?.toUpperCase();
  if (h != null) {
    for (final hue in PlengoColors.all) {
      if (_hex(hue.base) == h) return hue;
    }
    final legacy = _legacyHues[h];
    if (legacy != null) return PlengoColors.byName(legacy);
  }
  return subjectHue(id);
}

/// A small round swatch of a deck's colour (decorative).
class DeckColorDot extends StatelessWidget {
  const DeckColorDot({super.key, required this.hue, this.size = 24});

  final PlengoHue hue;
  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: hue.base, shape: BoxShape.circle),
    ),
  );
}

/// "بطاقاتي": the student's private decks (spec §13.9). Works offline; changes sync in the background.
/// Redesign: V-MyDecks.
class MyDecksScreen extends ConsumerStatefulWidget {
  const MyDecksScreen({super.key});

  @override
  ConsumerState<MyDecksScreen> createState() => _MyDecksScreenState();
}

class _MyDecksScreenState extends ConsumerState<MyDecksScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(myDecksSyncProvider).syncNow();
  }

  @override
  Widget build(BuildContext context) {
    final decks = ref.watch(myDecksProvider);
    final s = context.surface;
    listenForSyncNotices(context, ref);
    return Scaffold(
      appBar: plengoAppBar(context, title: 'بطاقاتي'),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 12),
          child: PlengoButton(
            label: 'مجموعة جديدة',
            icon: Icons.add_rounded,
            onPressed: () => createDeck(context, ref),
          ),
        ),
      ),
      body: AsyncView(
        value: decks,
        onRetry: () => ref.invalidate(myDecksProvider),
        data: (list) => RefreshIndicator(
          onRefresh: () => ref.read(myDecksSyncProvider).syncNow(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: list.isEmpty
                  ? ListView(
                      children: const [
                        EmptyState(
                          'أنشئ مجموعتك الأولى وأضف إليها بطاقاتك الخاصة',
                          icon: Icons.collections_bookmark_outlined,
                        ),
                      ],
                    )
                  : ListView.separated(
                      padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 24),
                      itemCount: list.length + 1,
                      separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 14 : PlengoSpace.listGap),
                      itemBuilder: (context, i) {
                        if (i == 0) {
                          return Text(
                            'مجموعاتك الخاصة من البطاقات. أضف نصاً أو صورة على كل وجه.',
                            style: PlengoType.sub.copyWith(color: s.mute),
                          );
                        }
                        final d = list[i - 1];
                        return StripRow(
                          color: deckHue(d.deck.color, d.deck.id).base,
                          stripWidth: 12,
                          onTap: () => context.go('${Routes.myDecks}/${d.deck.id}'),
                          semanticsLabel: '${d.deck.name}، ${cardCountLabel(d.cardCount)}',
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(d.deck.name, style: PlengoType.rowTitle.copyWith(color: s.ink)),
                                    Text(
                                      cardCountLabel(d.cardCount),
                                      style: PlengoType.caption.copyWith(color: s.mute),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right_rounded, color: s.mute),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the server's refusals from the last sync once.
void listenForSyncNotices(BuildContext context, WidgetRef ref) {
  ref.listen(myDecksSyncNoticeProvider, (_, rejected) {
    if (rejected.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(rejectionMessage(rejected.first))));
    ref.read(myDecksSyncNoticeProvider.notifier).clear();
  });
}

/// Creates a deck (after the quota check) and returns its id.
Future<String?> createDeck(BuildContext context, WidgetRef ref) async {
  final store = ref.read(myDecksStoreProvider);
  if (await store.liveDeckCount() >= userDeckQuota) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('وصلت إلى الحد الأقصى: 50 مجموعة')));
    }
    return null;
  }
  if (!context.mounted) return null;
  final result = await showDeckForm(context);
  if (result == null) return null;
  final id = uuidV4();
  await store.saveDeck(id: id, name: result.name, color: result.color);
  ref.read(myDecksSyncProvider).schedule();
  return id;
}

/// The name-and-colour form of a deck (new or renamed) in a bottom sheet.
Future<({String name, String? color})?> showDeckForm(BuildContext context, {LocalDeckRow? initial}) =>
    showPlengoSheet<({String name, String? color})>(
      context: context,
      title: initial == null ? 'مجموعة جديدة' : 'تعديل المجموعة',
      builder: (_) => DeckForm(initial: initial),
    );

/// Name and colour of a deck: a name field and the six-colour picker (V-MyDecks).
class DeckForm extends StatefulWidget {
  const DeckForm({super.key, this.initial});

  final LocalDeckRow? initial;

  @override
  State<DeckForm> createState() => _DeckFormState();
}

class _DeckFormState extends State<DeckForm> {
  late final _name = TextEditingController(text: widget.initial?.name);
  late String? _color = _initialColor();

  String _initialColor() {
    final i = widget.initial;
    if (i == null) return _hex(PlengoColors.pink.base);
    return _hex(deckHue(i.color, i.id).base);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final valid = _name.text.trim().isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('deck-name'),
          controller: _name,
          autofocus: true,
          maxLength: 100,
          decoration: const InputDecoration(labelText: 'اسم المجموعة', hintText: 'مثلاً: قوانين الكيمياء'),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 4),
        Text('اللون', style: PlengoType.chip.copyWith(fontSize: 13, color: s.ink)),
        const SizedBox(height: 8),
        Semantics(
          label: 'لون المجموعة',
          container: true,
          child: Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              for (final hue in PlengoColors.all)
                _Swatch(
                  hue: hue,
                  selected: _color == _hex(hue.base),
                  onTap: () => setState(() => _color = _hex(hue.base)),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        PlengoButton(
          label: widget.initial == null ? 'إنشاء المجموعة' : 'حفظ',
          onPressed: valid ? () => Navigator.pop(context, (name: _name.text.trim(), color: _color)) : null,
        ),
      ],
    );
  }
}

/// One colour of the picker: a 44 circle in a 48 target; the chosen one has an ink ring and a check.
class _Swatch extends StatelessWidget {
  const _Swatch({required this.hue, required this.selected, required this.onTap});

  final PlengoHue hue;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return Semantics(
      button: true,
      selected: selected,
      inMutuallyExclusiveGroup: true,
      label: deckColorNames[hue.name],
      excludeSemantics: true,
      onTap: onTap,
      child: InkResponse(
        onTap: onTap,
        radius: 26,
        child: SizedBox.square(
          dimension: 48,
          child: Center(
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: hue.base,
                shape: BoxShape.circle,
                border: Border.all(color: selected ? s.ink : s.card, width: 3),
              ),
              child: selected ? Icon(Icons.check_rounded, size: 22, color: hue.onFill) : null,
            ),
          ),
        ),
      ),
    );
  }
}
