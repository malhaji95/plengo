import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../core/content/media_uploader.dart';
import '../../shared/widgets/network_avatar.dart';
import '../access/access_providers.dart';
import '../my_decks/card_editor_screen.dart';
import '../subjects/catalog_providers.dart';
import '../teachers/teacher_providers.dart';
import '../offline/offline_providers.dart';
import '../../shared/widgets/responsive.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).value;
    final appearance = ref.watch(appearanceProvider);
    final appearanceCtl = ref.read(appearanceProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 8),
          children: [
            if (me != null)
              ListTile(
                leading: _AvatarButton(me: me),
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
              leading: const Icon(Icons.key_outlined),
              title: const Text('صلاحيات الوصول'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.go(Routes.myAccess),
            ),
            if (ref.watch(couponRedemptionProvider))
              ListTile(
                leading: const Icon(Icons.vpn_key_outlined),
                title: const Text('إدخال كود التفعيل'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => context.push(Routes.redeem),
              ),
            if (ref.watch(offlinePacksAvailableProvider))
              ListTile(
                leading: const Icon(Icons.download_for_offline_outlined),
                title: const Text('المحتوى المحمّل'),
                subtitle: const Text('التحميل دون اتصال والمساحة المستخدمة'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => context.go(Routes.offlineStorage),
              ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('الإشعارات والهدف اليومي'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.go(Routes.notificationSettings),
            ),
            ListTile(
              leading: const Icon(Icons.school_outlined),
              title: const Text('المرحلة التعليمية'),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => context.go(Routes.placement),
            ),
            if (ref.watch(teacherFollowingEnabledProvider))
              ListTile(
                leading: const Icon(Icons.groups_outlined),
                title: const Text('المدرسون الذين أتابعهم'),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => context.go(Routes.following),
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

/// Profile photo: tap to choose a new one (uploaded, processed to 400 px, then attached).
class _AvatarButton extends ConsumerStatefulWidget {
  const _AvatarButton({required this.me});

  final Me me;

  @override
  ConsumerState<_AvatarButton> createState() => _AvatarButtonState();
}

class _AvatarButtonState extends ConsumerState<_AvatarButton> {
  bool _busy = false;

  Future<void> _change() async {
    final bytes = await pickImage(context, ref, maxSide: 800);
    if (bytes == null || !mounted) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final uploader = MediaUploader(ref.read(apiClientProvider));
      final id = await uploader.upload(bytes, MediaKind.avatar);
      final media = await uploader.waitReady(id);
      if (media.status != MediaFileStatus.ready) {
        throw const ApiException('VALIDATION_ERROR', 'تعذرت معالجة الصورة، جرّب صورة أخرى');
      }
      final me = await ref.read(catalogRepositoryProvider).updateAvatar(id);
      ref.read(authControllerProvider.notifier).setMe(me);
    } on ApiException catch (e) {
      messenger.showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    label: 'تغيير الصورة الشخصية',
    child: InkWell(
      customBorder: const CircleBorder(),
      onTap: _busy ? null : _change,
      child: _busy
          ? const SizedBox(
              width: 48,
              height: 48,
              child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()),
            )
          : NetworkAvatar(url: widget.me.avatarUrl, name: widget.me.fullName),
    ),
  );
}
