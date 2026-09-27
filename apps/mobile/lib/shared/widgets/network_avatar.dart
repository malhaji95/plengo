import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Circular photo from the CDN with an initial as fallback. Public image URLs are stable per media
/// version, so the URL itself is the cache key (spec §12.5).
class NetworkAvatar extends StatelessWidget {
  const NetworkAvatar({super.key, required this.url, required this.name, this.radius = 24});

  final String? url;
  final String name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = _initial(name);
    final fallback = CircleAvatar(
      radius: radius,
      backgroundColor: scheme.secondaryContainer,
      child: Text(
        initial,
        style: TextStyle(color: scheme.onSecondaryContainer, fontSize: radius * 0.8),
      ),
    );
    if (url == null) return fallback;
    return CachedNetworkImage(
      imageUrl: url!,
      cacheKey: url,
      imageBuilder: (_, image) => CircleAvatar(radius: radius, backgroundImage: image),
      placeholder: (_, _) => fallback,
      errorWidget: (_, _, _) => fallback,
    );
  }

  /// First letter of the name, skipping honorifics like "أ." (أستاذ).
  static String _initial(String name) {
    final words = name.split(RegExp(r'\s+')).where((w) => w.isNotEmpty && !w.endsWith('.')).toList();
    final word = words.isNotEmpty ? words.first : name.trim();
    return word.isEmpty ? '؟' : word.characters.first;
  }
}
