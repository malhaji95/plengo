import 'package:flutter/material.dart';

/// The Plengo wordmark (design/brand). [onBrand] is the full-colour sticker version for the yellow
/// brand background; otherwise the two-colour version on light themes and white on dark ones.
class BrandLogo extends StatelessWidget {
  const BrandLogo({super.key, this.height = 56, this.onBrand = false});

  final double height;
  final bool onBrand;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final variant = onBrand ? 'color' : (dark ? 'white' : 'blue');
    return Semantics(
      label: 'Plengo',
      image: true,
      child: ExcludeSemantics(
        child: Image.asset('assets/brand/wordmark-$variant.png', height: height, fit: BoxFit.contain),
      ),
    );
  }
}
