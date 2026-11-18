import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/content/my_decks_store.dart';
import '../../core/content/study_card.dart';
import '../../core/db/app_database.dart';
import '../../shared/ui/ui.dart';
import '../../shared/util/uuid.dart';
import '../../shared/widgets/responsive.dart';
import '../flashcards/card_face.dart';
import '../flashcards/decks_screen.dart' show cardCountLabel;
import '../flashcards/flashcard_ui.dart';
import '../my_decks/card_editor_screen.dart' show pickImage;
import '../my_decks/my_decks_providers.dart';
import '../plengo_cards/place_header.dart';
import 'card_templates.dart';
import 'make_cards_providers.dart';
import 'make_cards_screen.dart' show groupLocation;

enum _Step { name, card, done }

/// Creates a group (v3 §7): its name, then cards one by one — the front as text, the back as text
/// and/or an image — with «التالي» for the next card and «انتهت المجموعة» to finish, then the done
/// screen with the cards made and «إضافة بطاقات أخرى». The group is a deck of the student's own
/// (with [subjectId] and [templateKey]) saved on the device first and synced like بطاقاتي. With
/// [deckId] it adds cards to an existing group (no name step).
class CreateGroupScreen extends ConsumerStatefulWidget {
  const CreateGroupScreen({super.key, this.subjectId, this.templateKey, this.deckId});

  final String? subjectId;
  final String? templateKey;
  final String? deckId;

  @override
  ConsumerState<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends ConsumerState<CreateGroupScreen> {
  late _Step _step = widget.deckId == null ? _Step.name : _Step.card;
  late String? _deckId = widget.deckId;
  final _name = TextEditingController();
  final _front = TextEditingController();
  final _back = TextEditingController();
  Uint8List? _backImage;
  bool _saving = false;

  /// Cards made in this visit, in order.
  final _made = <String>[];

  bool get _adding => widget.deckId != null;

  @override
  void dispose() {
    _name.dispose();
    _front.dispose();
    _back.dispose();
    super.dispose();
  }

  bool get _cardFilled => _front.text.trim().isNotEmpty && (_back.text.trim().isNotEmpty || _backImage != null);
  bool get _cardEmpty => _front.text.trim().isEmpty && _back.text.trim().isEmpty && _backImage == null;

  void _snack(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  /// Creates the group on its first card (no empty groups are left behind).
  Future<String?> _ensureDeck() async {
    if (_deckId != null) return _deckId;
    final store = ref.read(myDecksStoreProvider);
    if (await store.liveDeckCount() >= userDeckQuota) {
      if (mounted) _snack('وصلت إلى الحد الأقصى: 50 مجموعة');
      return null;
    }
    final id = uuidV4();
    final hue = widget.subjectId != null ? subjectHue(widget.subjectId!) : PlengoColors.pink;
    await store.saveDeck(
      id: id,
      name: _name.text,
      subjectId: widget.subjectId,
      color: hueHex(hue),
      templateKey: widget.templateKey ?? CardTemplates.grid.key,
    );
    return _deckId = id;
  }

  /// Saves the card being written; true when it was saved.
  Future<bool> _saveCard() async {
    final store = ref.read(myDecksStoreProvider);
    if (await store.liveCardCount() >= userCardQuota) {
      if (mounted) _snack('وصلت إلى الحد الأقصى: 5000 بطاقة');
      return false;
    }
    final deckId = await _ensureDeck();
    if (deckId == null) return false;
    final id = uuidV4();
    await store.saveCustomCard(
      id: id,
      deckId: deckId,
      frontText: _front.text,
      backText: _back.text,
      backImage: _backImage,
    );
    ref.read(myDecksSyncProvider).schedule();
    _made.add(id);
    return true;
  }

  Future<void> _next() async {
    if (!_cardFilled || _saving) return;
    setState(() => _saving = true);
    final ok = await _saveCard();
    if (!mounted) return;
    setState(() {
      _saving = false;
      if (ok) {
        _front.clear();
        _back.clear();
        _backImage = null;
      }
    });
  }

  Future<void> _finish() async {
    if (_saving) return;
    if (!_cardEmpty) {
      if (!_cardFilled) return;
      setState(() => _saving = true);
      final ok = await _saveCard();
      if (!mounted) return;
      setState(() => _saving = false);
      if (!ok) return;
      _front.clear();
      _back.clear();
      _backImage = null;
    }
    setState(() => _step = _Step.done);
  }

  @override
  Widget build(BuildContext context) {
    final title = switch (_step) {
      _Step.name => 'مجموعة جديدة',
      _Step.card => _adding ? 'إضافة بطاقات' : _name.text.trim(),
      _Step.done => '',
    };
    return Scaffold(
      appBar: plengoAppBar(context, title: title),
      body: ContentWidth(
        child: switch (_step) {
          _Step.name => _nameStep(context),
          _Step.card => _cardStep(context),
          _Step.done => _DoneStep(
            deckId: _deckId!,
            made: _made,
            adding: _adding,
            onAddMore: () => setState(() => _step = _Step.card),
          ),
        },
      ),
    );
  }

  Widget _nameStep(BuildContext context) {
    final s = context.surface;
    final valid = _name.text.trim().isNotEmpty;
    final template = widget.templateKey ?? CardTemplates.grid.key;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Text('اسم المجموعة', style: PlengoType.section.copyWith(color: s.ink)),
        const SizedBox(height: 8),
        TextField(
          key: const Key('group.name'),
          controller: _name,
          autofocus: true,
          maxLength: 100,
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(hintText: 'مثلاً: قوانين الفيزياء'),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) {
            if (valid) setState(() => _step = _Step.card);
          },
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(PlengoRadius.flashcard),
          child: AspectRatio(
            aspectRatio: 1.6,
            child: TemplateFrame(
              templateKey: template,
              child: Center(
                child: Text(
                  valid ? _name.text.trim() : 'مجموعتي',
                  textAlign: TextAlign.center,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: PlengoType.section.copyWith(color: s.ink),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        PlengoButton(
          key: const Key('group.next'),
          label: 'التالي',
          icon: Icons.arrow_forward_rounded,
          onPressed: valid ? () => setState(() => _step = _Step.card) : null,
        ),
      ],
    );
  }

  Widget _cardStep(BuildContext context) {
    final s = context.surface;
    final number = _made.length + 1;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
      children: [
        Row(
          children: [
            PlengoChip(label: 'البطاقة $number', hue: PlengoColors.blue, icon: Icons.style_outlined),
            const SizedBox(width: 8),
            if (_made.isNotEmpty)
              Expanded(
                child: Text(
                  'أنشأت ${cardCountLabel(_made.length)}',
                  key: const Key('card.madeCount'),
                  textAlign: TextAlign.end,
                  style: PlengoType.caption.copyWith(color: s.mute),
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        PlengoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: PlengoChip(label: 'الوجه الأمامي', hue: PlengoColors.blue),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('card.front'),
                controller: _front,
                minLines: 2,
                maxLines: null,
                maxLength: userCardTextMax,
                decoration: const InputDecoration(hintText: 'السؤال أو المصطلح'),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        PlengoCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Align(
                alignment: AlignmentDirectional.centerStart,
                child: PlengoChip(label: 'الوجه الخلفي', hue: PlengoColors.pink),
              ),
              const SizedBox(height: 10),
              TextField(
                key: const Key('card.back'),
                controller: _back,
                minLines: 2,
                maxLines: null,
                maxLength: userCardTextMax,
                decoration: const InputDecoration(hintText: 'الإجابة (اختياري إذا أضفت صورة)'),
                onChanged: (_) => setState(() {}),
              ),
              if (_backImage != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(PlengoRadius.option),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: ColoredBox(
                      color: s.track,
                      child: CardFace(face: CardFaceView(localImage: _backImage)),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                PlengoButton(
                  label: 'إزالة الصورة',
                  icon: Icons.delete_outline_rounded,
                  variant: PlengoButtonVariant.ghost,
                  size: PlengoButtonSize.small,
                  expand: true,
                  onPressed: () => setState(() => _backImage = null),
                ),
              ] else
                PlengoButton(
                  key: const Key('card.backImage'),
                  label: 'رفع صورة للوجه الخلفي',
                  icon: Icons.add_photo_alternate_outlined,
                  variant: PlengoButtonVariant.secondary,
                  size: PlengoButtonSize.small,
                  expand: true,
                  onPressed: () async {
                    final bytes = await pickImage(context, ref);
                    if (bytes != null && mounted) setState(() => _backImage = bytes);
                  },
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        PlengoButton(
          key: const Key('card.next'),
          label: 'التالي',
          icon: Icons.arrow_forward_rounded,
          busy: _saving,
          onPressed: _cardFilled ? _next : null,
        ),
        const SizedBox(height: 10),
        PlengoButton(
          key: const Key('card.finish'),
          label: 'انتهت المجموعة',
          icon: Icons.check_circle_outline_rounded,
          variant: PlengoButtonVariant.secondary,
          onPressed: (_cardEmpty && _made.isNotEmpty) || _cardFilled ? _finish : null,
        ),
        if (!_cardFilled)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'اكتب الوجه الأمامي، ثم نصاً أو صورة على الوجه الخلفي',
              textAlign: TextAlign.center,
              style: PlengoType.caption.copyWith(color: s.mute),
            ),
          ),
      ],
    );
  }
}

/// «تم إنشاء مجموعة الفلاش كاردز!»: the group, the cards made and «إضافة بطاقات أخرى».
class _DoneStep extends ConsumerWidget {
  const _DoneStep({required this.deckId, required this.made, required this.adding, required this.onAddMore});

  final String deckId;
  final List<String> made;
  final bool adding;
  final VoidCallback onAddMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.surface;
    final deck = ref.watch(myDeckProvider(deckId)).value;
    final cards = ref.watch(myDeckCardsProvider(deckId)).value ?? const <LocalCardRow>[];
    final shown = adding ? cards.where((c) => made.contains(c.id)).toList() : cards;
    final subjects = ref.watch(studentSubjectsProvider).value ?? const [];
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
      children: [
        const Center(
          child: ConfettiDots(
            child: CardStackArt(icon: Icons.check_circle_rounded, hue: PlengoColors.green, size: 96),
          ),
        ),
        const SizedBox(height: 8),
        Semantics(
          header: true,
          child: Text(
            adding ? 'تمت إضافة البطاقات!' : 'تم إنشاء مجموعة الفلاش كاردز!',
            textAlign: TextAlign.center,
            style: PlengoType.title.copyWith(fontSize: 22, color: s.ink),
          ),
        ),
        const SizedBox(height: 14),
        if (deck != null)
          PlengoCard(
            child: Row(
              children: [
                SubjectIconTile(icon: Icons.style_rounded, hue: groupHue(deck)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deck.name, style: PlengoType.section.copyWith(color: s.ink)),
                      Text(
                        '${cardCountLabel(cards.length)} · ${subjectNameOf(subjects, deck.subjectId)} · مجموعتك الخاصة',
                        style: PlengoType.caption.copyWith(color: s.mute),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        SectionHeader(adding ? 'البطاقات المضافة' : 'البطاقات المنشأة', top: 12),
        for (final (i, c) in shown.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: ActionRow(
              key: Key('done.card.${c.id}'),
              title: c.frontText ?? '',
              caption: c.backText ?? (c.backLocalImage != null || c.backImageJson != null ? 'صورة' : null),
              leading: Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: PlengoColors.blue.soft, borderRadius: BorderRadius.circular(10)),
                child: Text('${i + 1}', style: PlengoType.chip.copyWith(color: PlengoColors.blue.ink)),
              ),
            ),
          ),
        const SizedBox(height: 12),
        PlengoButton(
          key: const Key('done.open'),
          label: 'عرض المجموعة',
          icon: Icons.check_circle_rounded,
          onPressed: () => context.go(groupLocation(deckId)),
        ),
        const SizedBox(height: 10),
        PlengoButton(
          key: const Key('done.addMore'),
          label: 'إضافة بطاقات أخرى',
          icon: Icons.add_circle_outline_rounded,
          variant: PlengoButtonVariant.secondary,
          onPressed: onAddMore,
        ),
        const SizedBox(height: 14),
        PlengoCard(
          color: s.isDark ? null : PlengoColors.blue.soft,
          child: Row(
            children: [
              Icon(Icons.edit_note_rounded, color: s.isDark ? s.ink : PlengoColors.blue.ink),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'مجموعتك قابلة للتعديل دائماً: أضف بطاقات أو عدّلها أو احذفها في أي وقت.',
                  style: PlengoType.caption.copyWith(color: s.isDark ? s.ink : PlengoColors.blue.ink),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
