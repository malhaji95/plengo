import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every asset bundled with this build, read once from the asset manifest. Art the owner sends later
/// (drawer illustration, subject headers, splash video) is dropped into its folder; until then the
/// path is simply missing and screens draw a placeholder. Never throws: a manifest that cannot be read
/// counts as "no optional assets".
final bundledAssetsProvider = FutureProvider<Set<String>>((ref) async {
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest.listAssets().toSet();
  } catch (_) {
    return const {};
  }
});

/// Whether [path] is bundled (false while the manifest loads).
bool assetBundled(WidgetRef ref, String path) => ref.watch(bundledAssetsProvider).value?.contains(path) ?? false;

/// [path] when it is in the bundle, else [placeholder]. Decorative: no semantics of its own.
class OptionalAssetImage extends ConsumerWidget {
  const OptionalAssetImage({
    super.key,
    required this.path,
    required this.placeholder,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
  });

  final String path;
  final Widget placeholder;
  final BoxFit fit;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!assetBundled(ref, path)) return placeholder;
    return Image.asset(
      path,
      fit: fit,
      alignment: alignment,
      excludeFromSemantics: true,
      errorBuilder: (_, _, _) => placeholder,
    );
  }
}
