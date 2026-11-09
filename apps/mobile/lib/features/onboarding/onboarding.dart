import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../shared/widgets/brand_logo.dart';
import '../../shared/ui/ui.dart';

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

typedef _Page = ({IconData icon, PlengoHue hue, String title, String body});

const _pages = <_Page>[
  (
    icon: Icons.school_rounded,
    hue: PlengoColors.blue,
    title: 'رحلتك التعليمية أسهل مع Plengo',
    body: 'أسئلة واختبارات وبطاقات مراجعة لكل مادة، في مكان واحد.',
  ),
  (
    icon: Icons.style_rounded,
    hue: PlengoColors.pink,
    title: 'تعلّم بطريقتك',
    body: 'تدرّب على الأسئلة، وراجع بالبطاقات الذكية، واختبر نفسك قبل الامتحان.',
  ),
  (
    icon: Icons.emoji_events_rounded,
    hue: PlengoColors.green,
    title: 'حقّق أهدافك',
    body: 'هدف يومي وسلسلة أيام متتالية وتقدّم واضح في كل مادة.',
  ),
];

/// V-Onboarding: three short intro pages before the first sign-in. «تخطي» and «لدي حساب — تسجيل الدخول»
/// mark them seen and show login; «ابدأ الآن» marks them seen and opens registration.
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

  void _start() {
    // Read the router first: finishing rebuilds the login screen and unmounts this view.
    final router = GoRouter.of(context);
    _finish();
    unawaited(router.push(Routes.register));
  }

  void _next() {
    if (_page == _pages.length - 1) return _finish();
    if (PlengoMotion.reduced(context)) {
      _controller.jumpToPage(_page + 1);
    } else {
      unawaited(_controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final last = _page == _pages.length - 1;
    return Scaffold(
      backgroundColor: s.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 8, 0),
                  child: Row(
                    children: [
                      // 30 high, as in the design.
                      const BrandLogo(height: 30),
                      const Spacer(),
                      PlengoButton(
                        label: 'تخطي',
                        variant: PlengoButtonVariant.ghost,
                        size: PlengoButtonSize.small,
                        onPressed: _finish,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _pages.length,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, i) => _PageBody(page: _pages[i]),
                  ),
                ),
                _Dots(count: _pages.length, index: _page),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(20, 20, 20, 16),
                  child: last
                      ? Column(
                          children: [
                            PlengoButton(label: 'ابدأ الآن', variant: PlengoButtonVariant.brand, onPressed: _start),
                            const SizedBox(height: 8),
                            PlengoButton(
                              label: 'لدي حساب — تسجيل الدخول',
                              variant: PlengoButtonVariant.ghost,
                              onPressed: _finish,
                            ),
                          ],
                        )
                      : PlengoButton(label: 'التالي', onPressed: _next),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Page position: the active dot is a 28-wide blue pill.
class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.index});

  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final idle = s.isDark ? const Color(0xFF4A4741) : const Color(0xFFD9D3C7);
    return Semantics(
      label: 'الصفحة ${index + 1} من $count',
      child: ExcludeSemantics(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < count; i++)
              AnimatedContainer(
                duration: PlengoMotion.of(context, const Duration(milliseconds: 200)),
                width: i == index ? 28 : 10,
                height: 10,
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(5), color: i == index ? s.action : idle),
              ),
          ],
        ),
      ),
    );
  }
}

class _PageBody extends StatelessWidget {
  const _PageBody({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 28, vertical: 8),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight - 16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Illustration(page: page),
              const SizedBox(height: 24),
              Semantics(
                header: true,
                child: Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: PlengoType.title.copyWith(color: s.ink),
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 300),
                child: Text(
                  page.body,
                  textAlign: TextAlign.center,
                  style: PlengoType.sub.copyWith(fontSize: 16, color: s.mute),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A big icon in a coloured circle with a soft 16 dp ring and confetti dots. Decorative only; swap
/// the icon for an illustration later.
class _Illustration extends StatelessWidget {
  const _Illustration({required this.page});

  final _Page page;

  @override
  Widget build(BuildContext context) {
    final hue = page.hue;
    return ExcludeSemantics(
      child: ConfettiDots(
        spread: 30,
        child: Container(
          width: 180,
          height: 180,
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: hue.base,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: hue.soft, spreadRadius: 16)],
          ),
          child: Icon(page.icon, size: 84, color: hue.onFill),
        ),
      ),
    );
  }
}
