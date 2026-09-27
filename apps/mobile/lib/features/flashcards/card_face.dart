import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';

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

/// Warms the image cache for the next cards (spec §22.9: prefetch the next 3).
final cardImagePrefetchProvider = Provider<void Function(BuildContext, Iterable<CardImage>)>(
  (ref) => (context, images) {
    for (final image in images) {
      precacheImage(CachedNetworkImageProvider(image.fullUrl, cacheKey: '${image.cacheKey}:full'), context);
    }
  },
);

/// A flashcard that flips between its front and back images.
class FlashcardView extends ConsumerWidget {
  const FlashcardView({super.key, required this.card, required this.flipped, required this.onTap});

  final StudentCard card;
  final bool flipped;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final build = ref.watch(cardImageBuilderProvider);
    final face = flipped ? card.back : card.front;
    return Semantics(
      button: true,
      label: flipped ? 'الوجه الخلفي للبطاقة' : 'الوجه الأمامي للبطاقة',
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) => AnimatedBuilder(
            animation: animation,
            child: child,
            builder: (context, child) => Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY((1 - animation.value) * math.pi / 2),
              child: child,
            ),
          ),
          child: Card(
            key: ValueKey('${card.id}:$flipped'),
            clipBehavior: Clip.antiAlias,
            child: AspectRatio(aspectRatio: (face.width ?? 3) / (face.height ?? 2), child: build(context, face)),
          ),
        ),
      ),
    );
  }
}
