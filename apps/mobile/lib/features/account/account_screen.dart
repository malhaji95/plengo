import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).value;
    final appearance = ref.watch(appearanceProvider);
    final appearanceCtl = ref.read(appearanceProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          if (me != null)
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person)),
              title: Text(me.fullName),
              subtitle: Text(me.email, textDirection: TextDirection.ltr, textAlign: TextAlign.right),
            ),
          const Divider(),
          const _SectionTitle('المظهر'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('تلقائي')),
                ButtonSegment(value: ThemeMode.light, label: Text('فاتح')),
                ButtonSegment(value: ThemeMode.dark, label: Text('داكن')),
              ],
              selected: {appearance.themeMode},
              onSelectionChanged: (s) => appearanceCtl.setThemeMode(s.first),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('خط صغير')),
                ButtonSegment(value: 1, label: Text('عادي')),
                ButtonSegment(value: 2, label: Text('كبير')),
              ],
              selected: {appearance.fontStep},
              onSelectionChanged: (s) => appearanceCtl.setFontStep(s.first),
            ),
          ),
          const Divider(height: 32),
          ListTile(
            leading: const Icon(Icons.school_outlined),
            title: const Text('المرحلة التعليمية'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.go(Routes.placement),
          ),
          ListTile(
            leading: const Icon(Icons.devices_outlined),
            title: const Text('الأجهزة المتصلة'),
            trailing: const Icon(Icons.chevron_left),
            onTap: () => context.go(Routes.sessions),
          ),
          ListTile(
            leading: Icon(Icons.logout, color: Theme.of(context).colorScheme.error),
            title: Text('تسجيل الخروج', style: TextStyle(color: Theme.of(context).colorScheme.error)),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Text(text, style: Theme.of(context).textTheme.titleSmall),
    );
  }
}
