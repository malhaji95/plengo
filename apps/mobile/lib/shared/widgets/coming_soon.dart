import 'package:flutter/material.dart';

import '../../features/shell/app_drawer.dart';
import '../ui/ui.dart';

/// A section that is planned but not built yet (v3): its title in the app bar and a «قريباً» empty
/// state, optionally with a link to what already works. Main places ([mainPlace]) get the drawer
/// button; sub-pages get back.
class ComingSoonScaffold extends StatelessWidget {
  const ComingSoonScaffold({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.hourglass_empty_rounded,
    this.hue = PlengoColors.yellow,
    this.mainPlace = false,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final PlengoHue hue;
  final bool mainPlace;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final menu = mainPlace ? DrawerMenuButton.leadingOf(context) : null;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: mainPlace ? menu : const PlengoBackButton(),
        leadingWidth: kPlengoLeadingWidth,
        titleSpacing: mainPlace && menu == null ? PlengoSpace.screen : null,
        title: Text(title),
      ),
      body: SingleChildScrollView(
        child: PlengoEmptyState(
          title: 'قريباً',
          message: message ?? 'نعمل على هذا القسم، وسيصلك في تحديث قادم.',
          icon: icon,
          hue: hue,
          actionLabel: actionLabel,
          onAction: onAction,
        ),
      ),
    );
  }
}
