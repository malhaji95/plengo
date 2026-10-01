import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import '../../shared/widgets/brand_logo.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    // Same yellow as the native launch screen, so start-up is one continuous brand moment.
    return Scaffold(
      backgroundColor: BrandColors.yellow,
      body: Center(
        child: auth.hasError
            ? Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      auth.error is ApiException ? (auth.error! as ApiException).message : ApiException.genericMessage,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => ref.read(authControllerProvider.notifier).retry(),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ],
                ),
              )
            : const Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  BrandLogo(height: 96, onBrand: true),
                  SizedBox(height: 32),
                  CircularProgressIndicator(color: BrandColors.ink),
                ],
              ),
      ),
    );
  }
}
