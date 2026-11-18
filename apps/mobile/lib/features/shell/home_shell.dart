import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../shared/ui/ui.dart';
import '../home/home_providers.dart';
import '../quizzes/quiz_providers.dart';
import '../offline/offline_providers.dart';
import '../loyalty/loyalty_repository.dart' show loyaltyEnabledProvider;
import 'app_drawer.dart';

/// Bottom navigation plus a side drawer on phones, a permanent side rail on wide (web/tablet) layouts
/// (spec §23.1, §24, v3 §1). The bottom bar holds the five main places; the drawer and the rail list
/// every place, with المحفوظات and المراجعة under a divider. While signed in, exams submitted offline are
/// retried every minute (spec §15.2).
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

  final _scaffold = GlobalKey<ScaffoldState>();

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

  void _go(int branch) {
    // Returning to Home shows fresh counts (due cards, goal, unread), keeping the old ones meanwhile.
    if (branch == ShellBranch.home) ref.invalidate(homeProvider);
    shell.goBranch(branch, initialLocation: branch == shell.currentIndex);
  }

  void _openMenu() => _scaffold.currentState?.openDrawer();

  /// The drawer / rail menu; the active place is filled yellow. Pushed places (نقاطي) open over the shell.
  Widget _menu({required bool drawer}) {
    final places = visibleDrawerPlaces(loyalty: ref.watch(loyaltyEnabledProvider));
    return PlengoSideRail(
      key: Key(drawer ? 'shell.drawer' : 'shell.rail'),
      destinations: [for (final p in places) p.destination],
      selectedIndex: places.indexWhere((p) => p.route == null && p.branch == shell.currentIndex),
      dividerBefore: drawerDividerBefore,
      width: drawer ? 288 : PlengoSpace.railWidth,
      border: !drawer,
      footer: const DrawerArt(),
      onSelected: (i) {
        if (drawer) Navigator.of(context).pop();
        final route = places[i].route;
        route == null ? _go(places[i].branch) : context.push(route);
      },
    );
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
            _menu(drawer: false),
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
      key: _scaffold,
      drawer: Drawer(
        width: 288,
        backgroundColor: context.surface.card,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadiusDirectional.horizontal(end: Radius.circular(PlengoRadius.card)),
        ),
        clipBehavior: Clip.antiAlias,
        child: _menu(drawer: true),
      ),
      body: ShellMenuScope(openMenu: _openMenu, child: content),
      bottomNavigationBar: PlengoNavBar(
        destinations: bottomBarDestinations,
        // Places outside the bar (المحفوظات, المراجعة, …) select no tab.
        selectedIndex: shell.currentIndex < ShellBranch.bottomBarCount ? shell.currentIndex : -1,
        onSelected: _go,
      ),
    );
  }
}
