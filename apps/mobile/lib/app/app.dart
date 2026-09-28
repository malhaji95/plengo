import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';
import 'router.dart';
import 'theme.dart';

/// Arabic-only, right-to-left app (spec §25).
class PlengoApp extends ConsumerWidget {
  const PlengoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appearance = ref.watch(appearanceProvider);
    return MaterialApp.router(
      title: 'Plengo',
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: appearance.themeMode,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) => MediaQuery(
        // The app's size setting multiplies the phone's own text size; it never replaces it.
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: _ScaledBy(MediaQuery.textScalerOf(context), appearance.textScale)),
        child: child!,
      ),
    );
  }
}

/// The system text scaler multiplied by the in-app font-size factor (spec §25).
class _ScaledBy extends TextScaler {
  const _ScaledBy(this.system, this.factor);

  final TextScaler system;
  final double factor;

  @override
  double scale(double fontSize) => system.scale(fontSize) * factor;

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => system.scale(14) / 14 * factor;

  @override
  bool operator ==(Object other) => other is _ScaledBy && other.system == system && other.factor == factor;

  @override
  int get hashCode => Object.hash(system, factor);
}
