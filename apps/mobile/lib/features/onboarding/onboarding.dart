import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme.dart';
import '../../shared/widgets/brand_logo.dart';
import '../../shared/widgets/ui_kit.dart';

/// Whether this device has seen the intro (spec §23.2 screen 2). Stored locally, so it shows once
/// per installation and never again after the first skip or start.
class OnboardingController extends AsyncNotifier<bool> {
  static const _key = 'onboarding.seen';

  @override
  Future<bool> build() async => await ref.read(databaseProvider).getValue(_key) != null;

  Future<void> finish() async {
    state = const AsyncData(true);
    await ref.read(databaseProvider).setValue(_key, '1');
  }
}

final onboardingSeenProvider = AsyncNotifierProvider<OnboardingController, bool>(OnboardingController.new);

typedef _Page = ({IconData icon, Color tint, String title, String body});

const _pages = <_Page>[
  (
    icon: Icons.school_rounded,
    tint: BrandColors.tintYellow,
    title: 'رحلتك التعليمية أسهل مع Plengo',
    body: 'أسئلة واختبارات وبطاقات مراجعة لكل مادة، في مكان واحد.',
  ),
  (
    icon: Icons.style_rounded,
    tint: BrandColors.tintBlue,
    title: 'تعلّم بطريقتك',
    body: 'تدرّب على الأسئلة، وراجع بالبطاقات الذكية، واختبر نفسك قبل الامتحان.',
  ),
  (
    icon: Icons.emoji_events_rounded,
    tint: BrandColors.tintGreen,
    title: 'حقّق أهدافك',
    body: 'هدف يومي وسلسلة أيام متتالية وتقدّم واضح في كل مادة.',
  ),
];

/// Three short intro pages before the first sign-in; skip or start marks them seen.
class OnboardingView extends ConsumerStatefulWidget {
  const OnboardingView({super.key});

  @override
  ConsumerState<OnboardingView> createState() => _OnboardingViewState();
}

class _OnboardingViewState extends ConsumerState<OnboardingView> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _finish() => unawaited(ref.read(onboardingSeenProvider.notifier).finish());

  void _next() {
    if (_page == _pages.length - 1) return _finish();
    final reduce = MediaQuery.of(context).disableAnimations;
    if (reduce) {
      _controller.jumpToPage(_page + 1);
    } else {
      unawaited(_controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
                  child: Row(
                    children: [
                      const BrandLogo(height: 36),
                      const Spacer(),
                      if (!last) TextButton(onPressed: _finish, child: const Text('تخطي')),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => _PageBody(page: _pages[i], index: i),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < _pages.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: i == _page ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: i == _page ? scheme.primary : scheme.outlineVariant,
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                  child: FilledButton(onPressed: _next, child: Text(last ? 'ابدأ الآن' : 'التالي')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.page, required this.index});

  final _Page page;
  final int index;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _Illustration(page: page, index: index),
          const SizedBox(height: 32),
          Text(page.title, textAlign: TextAlign.center, style: text.headlineSmall),
          const SizedBox(height: 12),
          Text(
            page.body,
            textAlign: TextAlign.center,
            style: text.bodyLarge?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

/// A big icon in a soft circle with a few confetti dots in the logo colours around it.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.page, required this.index});

  final _Page page;
  final int index;

  @override
  Widget build(BuildContext context) {
    const dots = [
      (Alignment(-0.9, -0.7), 14.0),
      (Alignment(0.85, -0.85), 10.0),
      (Alignment(0.95, 0.55), 16.0),
      (Alignment(-0.75, 0.8), 10.0),
      (Alignment(0.1, -1.0), 8.0),
    ];
    return ExcludeSemantics(
      child: SizedBox(
        width: 240,
        height: 220,
        child: Stack(
          children: [
            for (final (i, (align, size)) in dots.indexed)
              Align(
                alignment: align,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: BrandColors.accents[(i + index * 2) % BrandColors.accents.length],
                    shape: i.isEven ? BoxShape.circle : BoxShape.rectangle,
                    borderRadius: i.isEven ? null : BorderRadius.circular(3),
                  ),
                ),
              ),
            Center(child: SpotIcon(page.icon, tint: page.tint, size: 170)),
          ],
        ),
      ),
    );
  }
}
