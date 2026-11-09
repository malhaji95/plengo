import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../shared/ui/ui.dart';
import '../home/home_providers.dart';
import '../quizzes/quiz_providers.dart';
import '../offline/offline_providers.dart';

/// Bottom navigation on phones, a side rail on wide (web/tablet) layouts (spec §23.1, §24). While
/// signed in, exams submitted offline are retried every minute (spec §15.2).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  Timer? _examSync;
  StreamSubscription<Object?>? _connectivity;

  StatefulNavigationShell get shell => widget.shell;

  static const _destinations = [
    PlengoNavDestination(icon: Icons.home_outlined, selectedIcon: Icons.home_rounded, label: 'الرئيسية'),
    PlengoNavDestination(icon: Icons.menu_book_outlined, selectedIcon: Icons.menu_book_rounded, label: 'المواد'),
    PlengoNavDestination(icon: Icons.style_outlined, selectedIcon: Icons.style_rounded, label: 'المراجعة'),
    PlengoNavDestination(icon: Icons.bookmark_border_rounded, selectedIcon: Icons.bookmark_rounded, label: 'المحفوظات'),
    PlengoNavDestination(icon: Icons.person_outline_rounded, selectedIcon: Icons.person_rounded, label: 'حسابي'),
  ];

  @override
  void initState() {
    super.initState();
    final sync = ref.read(examSyncProvider);
    unawaited(sync.syncNow());
    _examSync = Timer.periodic(const Duration(minutes: 1), (_) => sync.syncNow());
    // Offline packs: leases, offline attempts and updates when online; again when the connection returns.
    unawaited(ref.read(pushRegistrationProvider).start());
    final offline = ref.read(offlineControllerProvider.notifier);
    unawaited(offline.syncOnline());
    if (ref.read(offlinePacksAvailableProvider)) {
      _connectivity = ref.read(connectivityChangesProvider).listen((_) => offline.syncOnline());
    }
  }

  @override
  void dispose() {
    _examSync?.cancel();
    _connectivity?.cancel();
    super.dispose();
  }

  void _go(int index) {
    // Returning to Home shows fresh counts (due cards, goal, unread), keeping the old ones meanwhile.
    if (index == 0) ref.invalidate(homeProvider);
    shell.goBranch(index, initialLocation: index == shell.currentIndex);
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    // Online-only notice when the browser gives no persistent storage (spec §24).
    final content = ValueListenableBuilder<bool>(
      valueListenable: ref.watch(ephemeralStorageProvider),
      builder: (context, ephemeral, child) => ephemeral
          ? Column(
              children: [
                Material(
                  color: PlengoColors.orange.soft,
                  textStyle: TextStyle(fontFamily: PlengoType.family, color: PlengoColors.orange.ink),
                  child: const SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          Icon(Icons.storage_outlined, size: 20, color: Color(0xFF9A5205)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'متصفحك لا يسمح بالتخزين المحلي، لذلك يعمل التطبيق متصلاً فقط ولن تُحفظ المراجعة دون اتصال.',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(child: child!),
              ],
            )
          : child!,
      child: shell,
    );
    if (wide) {
      // Rail at the start edge (right in RTL); content centred and capped at 720 (V-Web).
      return Scaffold(
        body: Row(
          children: [
            PlengoSideRail(destinations: _destinations, selectedIndex: shell.currentIndex, onSelected: _go),
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: PlengoSpace.contentMaxWide),
                  child: content,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return Scaffold(
      body: content,
      bottomNavigationBar: PlengoNavBar(
        destinations: _destinations,
        selectedIndex: shell.currentIndex,
        onSelected: _go,
      ),
    );
  }
}
