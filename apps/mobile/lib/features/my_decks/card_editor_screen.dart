import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/api/generated/export.dart';
import '../../core/content/media_uploader.dart';
import '../../core/content/my_decks_store.dart';
import '../../core/content/study_card.dart';
import '../../core/db/app_database.dart';
import '../../shared/ui/ui.dart';
import '../../shared/util/uuid.dart';
import '../../shared/widgets/async_view.dart';
import '../flashcards/card_face.dart';
import '../flashcards/flashcard_ui.dart';
import 'my_decks_providers.dart';

/// Picks an image already scaled on the device: at most [maxSide] pixels on the long side, JPEG
/// quality 80 (spec §12.4: student images are compressed to ≤ 1080 px before upload). Tests replace it.
typedef ImagePick = Future<Uint8List?> Function({required bool camera, required double maxSide});

final imagePickProvider = Provider<ImagePick>(
  (ref) => ({required camera, required maxSide}) async {
    final file = await ImagePicker().pickImage(
      source: camera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: maxSide,
      maxHeight: maxSide,
      imageQuality: 80,
    );
    return file?.readAsBytes();
  },
);

/// Asks gallery or camera (camera only where available), then picks.
Future<Uint8List?> pickImage(BuildContext context, WidgetRef ref, {double maxSide = 1080}) async {
  final camera = await showPlengoSheet<bool>(
    context: context,
    title: 'إضافة صورة',
    builder: (context) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListRow(
          flat: true,
          icon: Icons.photo_library_outlined,
          hue: PlengoColors.blue,
          title: 'من المعرض',
          onTap: () => Navigator.pop(context, false),
        ),
        ListRow(
          flat: true,
          showDivider: false,
          icon: Icons.photo_camera_outlined,
          hue: PlengoColors.pink,
          title: 'التقاط صورة',
          onTap: () => Navigator.pop(context, true),
        ),
      ],
    ),
  );
  if (camera == null) return null;
  final bytes = await ref.read(imagePickProvider)(camera: camera, maxSide: maxSide);
  if (bytes == null) return null;
  String? problem;
  if (sniffImageType(bytes) == null) problem = 'نوع الصورة غير مدعوم';
  if (bytes.length > maxStudentUploadBytes) problem = 'حجم الصورة أكبر من 2 ميغابايت';
  if (problem != null) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(problem)));
    return null;
  }
  return bytes;
}

/// Creates or edits a custom card: each face has text (≤ 1,000 characters) and/or one image
/// (spec §13.9). Saved locally first; the sync uploads images and sends the card.
class CardEditorScreen extends ConsumerStatefulWidget {
  const CardEditorScreen({super.key, required this.deckId, this.cardId});

  final String deckId;
  final String? cardId;

  @override
  ConsumerState<CardEditorScreen> createState() => _CardEditorScreenState();
}

class _FaceDraft {
  final text = TextEditingController();
  Uint8List? picked;
  bool removed = false;
  CardImage? current;
  Uint8List? currentLocal;

  bool get hasImage => picked != null || (!removed && (current != null || currentLocal != null));
  CardFaceView view() => CardFaceView(
    text: text.text,
    image: removed || picked != null ? null : current,
    localImage: picked ?? (removed ? null : currentLocal),
  );
}

class _CardEditorScreenState extends ConsumerState<CardEditorScreen> {
  final _front = _FaceDraft();
  final _back = _FaceDraft();
  late final Future<LocalCardRow?> _loading;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loading = widget.cardId == null
        ? Future.value(null)
        : ref.read(myDecksStoreProvider).card(widget.cardId!).then((c) {
            if (c != null) {
              _front
                ..text.text = c.frontText ?? ''
                ..current = StudyCard.imageFromJson(c.frontImageJson)
                ..currentLocal = c.frontLocalImage;
              _back
                ..text.text = c.backText ?? ''
                ..current = StudyCard.imageFromJson(c.backImageJson)
                ..currentLocal = c.backLocalImage;
            }
            return c;
          });
  }

  @override
  void dispose() {
    _front.text.dispose();
    _back.text.dispose();
    super.dispose();
  }

  bool _filled(_FaceDraft f) => f.text.text.trim().isNotEmpty || f.hasImage;

  Future<void> _save() async {
    final store = ref.read(myDecksStoreProvider);
    if (widget.cardId == null && await store.liveCardCount() >= userCardQuota) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('وصلت إلى الحد الأقصى: 5000 بطاقة')));
      }
      return;
    }
    setState(() => _saving = true);
    await store.saveCustomCard(
      id: widget.cardId ?? uuidV4(),
      deckId: widget.deckId,
      frontText: _front.text.text,
      backText: _back.text.text,
      frontImage: _front.picked,
      backImage: _back.picked,
      removeFrontImage: _front.removed && _front.picked == null,
      removeBackImage: _back.removed && _back.picked == null,
    );
    ref.read(myDecksSyncProvider).schedule();
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final canSave = !_saving && _filled(_front) && _filled(_back);
    final s = context.surface;
    return Scaffold(
      appBar: plengoAppBar(
        context,
        title: widget.cardId == null ? 'بطاقة جديدة' : 'تعديل البطاقة',
        actions: [
          TextButton(
            onPressed: canSave ? _save : null,
            style: TextButton.styleFrom(
              foregroundColor: s.action,
              minimumSize: const Size(48, 48),
              textStyle: PlengoType.buttonSmall,
            ),
            child: const Text('حفظ'),
          ),
        ],
      ),
      body: FutureBuilder(
        future: _loading,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Align(alignment: Alignment.topCenter, child: PlengoLoadingSkeleton(hero: false));
          }
          if (widget.cardId != null && snap.data == null) return const EmptyState('لم تعد هذه البطاقة موجودة');
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 28),
                children: [
                  _FaceEditor(
                    label: 'الوجه الأمامي',
                    hue: PlengoColors.blue,
                    draft: _front,
                    fieldKey: 'front',
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  _FaceEditor(
                    label: 'الوجه الخلفي',
                    hue: PlengoColors.pink,
                    draft: _back,
                    fieldKey: 'back',
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 20),
                  PlengoButton(label: 'حفظ البطاقة', busy: _saving, onPressed: canSave ? _save : null),
                  if (!canSave && !_saving)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'اكتب نصاً أو أضف صورة على كل وجه',
                        textAlign: TextAlign.center,
                        style: PlengoType.caption.copyWith(color: s.mute),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// One face of the card: its text and/or image (from the gallery or the camera).
class _FaceEditor extends ConsumerWidget {
  const _FaceEditor({
    required this.label,
    required this.hue,
    required this.draft,
    required this.fieldKey,
    required this.onChanged,
  });

  final String label;
  final PlengoHue hue;
  final _FaceDraft draft;
  final String fieldKey;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.surface;
    return PlengoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [PlengoChip(label: label, hue: hue)],
          ),
          const SizedBox(height: 12),
          TextField(
            key: Key('$fieldKey-text'),
            controller: draft.text,
            maxLines: null,
            minLines: 2,
            maxLength: userCardTextMax,
            decoration: const InputDecoration(hintText: 'النص (اختياري إذا أضفت صورة)'),
            onChanged: (_) => onChanged(),
          ),
          const SizedBox(height: 4),
          if (draft.hasImage) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(PlengoRadius.option),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ColoredBox(
                  color: s.track,
                  child: CardFace(
                    face: CardFaceView(image: draft.view().image, localImage: draft.view().localImage),
                  ),
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
              onPressed: () {
                draft
                  ..picked = null
                  ..removed = true;
                onChanged();
              },
            ),
          ] else
            PlengoButton(
              key: Key('$fieldKey-image'),
              label: 'إضافة صورة',
              icon: Icons.add_photo_alternate_outlined,
              variant: PlengoButtonVariant.secondary,
              size: PlengoButtonSize.small,
              expand: true,
              onPressed: () async {
                final bytes = await pickImage(context, ref);
                if (bytes == null) return;
                draft.picked = bytes;
                onChanged();
              },
            ),
        ],
      ),
    );
  }
}
