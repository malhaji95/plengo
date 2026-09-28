import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    (icon: Icons.home_outlined, selected: Icons.home, label: 'الرئيسية'),
    (icon: Icons.menu_book_outlined, selected: Icons.menu_book, label: 'المواد'),
    (icon: Icons.style_outlined, selected: Icons.style, label: 'المراجعة'),
    (icon: Icons.bookmark_border, selected: Icons.bookmark, label: 'المحفوظات'),
    (icon: Icons.person_outline, selected: Icons.person, label: 'حسابي'),
  ];

  @override
  void initState() {
    super.initState();
    final sync = ref.read(examSyncProvider);
    unawaited(sync.syncNow());
    _examSync = Timer.periodic(const Duration(minutes: 1), (_) => sync.syncNow());
    // Offline packs: leases, offline attempts and updates when online; again when the connection returns.
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

  void _go(int index) => shell.goBranch(index, initialLocation: index == shell.currentIndex);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 600;
    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _go,
              labelType: NavigationRailLabelType.all,
              destinations: [
                for (final d in _destinations)
                  NavigationRailDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selected), label: Text(d.label)),
              ],
            ),
            const VerticalDivider(width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }
    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _go,
        destinations: [
          for (final d in _destinations)
            NavigationDestination(icon: Icon(d.icon), selectedIcon: Icon(d.selected), label: d.label),
        ],
      ),
    );
  }
}
