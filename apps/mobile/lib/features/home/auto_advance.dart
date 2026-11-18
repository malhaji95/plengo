import 'dart:async';

import 'package:flutter/widgets.dart';

import '../../shared/ui/ui.dart';

/// Moves a [PageView] to its next page every [autoAdvanceInterval] (wrapping to the first), as the
/// Home carousels do (v3 §2). Never with reduced motion or a single page; paused while a finger is on
/// it ([holdOnTouch]), restarting the full interval once it lifts.
mixin AutoAdvance<T extends StatefulWidget> on State<T> {
  Timer? _timer;
  bool _held = false;

  PageController get pager;
  int get pageCount;
  Duration get autoAdvanceInterval;

  /// Whether the pages are moving by themselves now (tests and semantics).
  bool get autoAdvancing => _timer != null;

  /// (Re)starts or stops the timer for the current page count and motion setting. Call from
  /// `didChangeDependencies` and `didUpdateWidget`.
  void syncAutoAdvance() {
    _timer?.cancel();
    _timer = null;
    if (pageCount < 2 || _held || PlengoMotion.reduced(context)) return;
    _timer = Timer.periodic(autoAdvanceInterval, (_) => _advance());
  }

  void _advance() {
    if (_held || !mounted || !pager.hasClients) return;
    final current = pager.page?.round() ?? 0;
    pager.animateToPage(
      (current + 1) % pageCount,
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeInOut,
    );
  }

  /// Pauses while touched.
  Widget holdOnTouch(Widget child) => Listener(
    onPointerDown: (_) {
      _held = true;
      _timer?.cancel();
      _timer = null;
    },
    onPointerUp: (_) => _release(),
    onPointerCancel: (_) => _release(),
    child: child,
  );

  void _release() {
    _held = false;
    if (mounted) syncAutoAdvance();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
