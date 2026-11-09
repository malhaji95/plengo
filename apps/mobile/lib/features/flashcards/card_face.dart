import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import '../../core/content/study_card.dart';
import '../../shared/ui/ui.dart';

typedef CardImageBuilder = Widget Function(BuildContext context, CardImage image);

/// Card images are cached by `{media id}:{version}:{variant}`, so a new signed URL for the same image
/// does not download it again (spec §12.5).
final cardImageBuilderProvider = Provider<CardImageBuilder>(
  (ref) =>
      (context, image) => CachedNetworkImage(
        imageUrl: image.fullUrl,
        cacheKey: '${image.cacheKey}:full',
        fit: BoxFit.contain,
        placeholder: (_, _) => const Center(child: CircularProgressIndicator()),
        errorWidget: (_, _, _) => const Center(child: Icon(Icons.broken_image_outlined, size: 48)),
      ),
);

/// Draws an image picked on this device that has not been uploaded yet.
final localImageBuilderProvider = Provider<Widget Function(BuildContext, Uint8List)>(
  (ref) =>
      (context, bytes) => Image.memory(bytes, fit: BoxFit.contain),
);

/// Warms the image cache for the next cards (spec §22.9: prefetch the next 3).
final cardImagePrefetchProvider = Provider<void Function(BuildContext, Iterable<CardImage>)>(
  (ref) => (context, images) {
    for (final image in images) {
      precacheImage(CachedNetworkImageProvider(image.fullUrl, cacheKey: '${image.cacheKey}:full'), context);
    }
  },
);

/// Whether [face] shows an image (the zoom button of Browse).
bool faceHasImage(CardFaceView face) => face.image != null || face.localImage != null;

/// A flashcard that flips between its two faces (V-FcBrowse / V-Flashcards): a 3D turn around the
/// vertical axis (≈500 ms, ease-out), or a crossfade when the system asks for reduced motion. Official
/// cards are images shown as they are (DECISIONS #14: no extra frame or logo); the student's own cards
/// can have text, an image or both on each face (spec §13.9). With [maxHeight], an image card is
/// narrowed so it fits that height.
class FlashcardView extends ConsumerWidget {
  const FlashcardView({super.key, required this.card, required this.flipped, required this.onTap, this.maxHeight});

  final StudyCard card;
  final bool flipped;
  final VoidCallback onTap;
  final double? maxHeight;

  static double? _aspect(CardFaceView f) {
    final text = f.text?.trim();
    if (text != null && text.isNotEmpty) return null;
    final w = f.image?.width, h = f.image?.height;
    if (w != null && h != null && w > 0 && h > 0) return w / h;
    return null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Widget face(bool back) => _FaceSurface(key: ValueKey('${card.key}:$back'), face: back ? card.back : card.front);
    final Widget body;
    if (PlengoMotion.reduced(context)) {
      body = AnimatedSwitcher(duration: const Duration(milliseconds: 200), child: face(flipped));
    } else {
      body = TweenAnimationBuilder<double>(
        key: ValueKey(card.key),
        tween: Tween(end: flipped ? 1 : 0),
        duration: PlengoMotion.flip,
        curve: Curves.easeOut,
        builder: (context, t, _) {
          final back = t >= 0.5;
          return Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0012)
              ..rotateY(back ? (t - 1) * math.pi : t * math.pi),
            child: face(back),
          );
        },
      );
    }
    final aspect = _aspect(flipped ? card.back : card.front);
    final h = maxHeight;
    return Semantics(
      button: true,
      label: flipped ? 'الوجه الخلفي للبطاقة' : 'الوجه الأمامي للبطاقة',
      onTapHint: 'اقلب البطاقة',
      child: GestureDetector(
        onTap: onTap,
        child: h != null && aspect != null
            ? ConstrainedBox(
                constraints: BoxConstraints(maxWidth: h * aspect),
                child: body,
              )
            : body,
      ),
    );
  }
}

/// The card surface: radius 26, card colour, a soft drop shadow (a line border in dark mode).
class _FaceSurface extends StatelessWidget {
  const _FaceSurface({super.key, required this.face});

  final CardFaceView face;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final r = BorderRadius.circular(PlengoRadius.flashcard);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: s.card,
        borderRadius: r,
        border: s.isDark ? Border.all(color: s.line) : null,
        boxShadow: s.isDark
            ? null
            : const [
                BoxShadow(color: Color(0x14000000), offset: Offset(0, 8)),
                BoxShadow(color: Color(0x1A3C2D0A), offset: Offset(0, 10), blurRadius: 24),
              ],
      ),
      child: ClipRRect(
        borderRadius: r,
        child: CardFace(face: face),
      ),
    );
  }
}

/// Opens [face] full screen with pinch-to-zoom (the zoom button of image cards).
Future<void> showCardZoom(BuildContext context, CardFaceView face) => Navigator.of(context).push(
  MaterialPageRoute<void>(
    fullscreenDialog: true,
    builder: (context) => Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        automaticallyImplyLeading: false,
        leading: IconButton(
          tooltip: 'إغلاق',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: InteractiveViewer(
        maxScale: 5,
        child: Center(
          child: Semantics(
            label: 'البطاقة مكبّرة',
            hint: 'باعد بإصبعين للتكبير',
            child: CardFace(face: face),
          ),
        ),
      ),
    ),
  ),
);

/// One face: an image-only face keeps the image's aspect ratio; text is centred below any image.
class CardFace extends ConsumerWidget {
  const CardFace({super.key, required this.face});

  final CardFaceView face;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final build = ref.watch(cardImageBuilderProvider);
    final image = face.localImage != null
        ? ref.watch(localImageBuilderProvider)(context, face.localImage!)
        : face.image != null
        ? build(context, face.image!)
        : null;
    final text = face.text?.trim();
    if (text == null || text.isEmpty) {
      if (image == null) return const AspectRatio(aspectRatio: 3 / 2, child: SizedBox());
      return AspectRatio(aspectRatio: (face.image?.width ?? 3) / (face.image?.height ?? 2), child: image);
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 220),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (image != null) ...[
              ConstrainedBox(constraints: const BoxConstraints(maxHeight: 280), child: image),
              const SizedBox(height: 16),
            ],
            Text(
              text,
              textAlign: TextAlign.center,
              style: PlengoType.question.copyWith(color: context.surface.ink),
            ),
          ],
        ),
      ),
    );
  }
}
