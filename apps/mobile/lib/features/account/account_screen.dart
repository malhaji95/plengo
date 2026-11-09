import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../core/content/media_uploader.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/network_avatar.dart';
import '../../shared/widgets/responsive.dart';
import '../access/access_providers.dart';
import '../auth/auth_widgets.dart';
import '../my_decks/card_editor_screen.dart';
import '../offline/offline_providers.dart';
import '../subjects/catalog_providers.dart';
import '../teachers/teacher_providers.dart';

/// V-Account: profile header, appearance, grouped settings, legal links and the sign-out / delete card.
class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(authControllerProvider).value;
    final appearance = ref.watch(appearanceProvider);
    final appearanceCtl = ref.read(appearanceProvider.notifier);
    final levelName = me == null
        ? null
        : ref.watch(levelsProvider).value?.where((l) => l.id == me.educationLevelId).firstOrNull?.nameAr;

    final settings = <_Item>[
      _Item(Icons.key_rounded, PlengoColors.green, 'صلاحيات الوصول', onTap: () => context.go(Routes.myAccess)),
      if (ref.watch(couponRedemptionProvider))
        _Item(
          Icons.vpn_key_rounded,
          PlengoColors.yellow,
          'إدخال كود التفعيل',
          onTap: () => context.push(Routes.redeem),
        ),
      if (ref.watch(offlinePacksAvailableProvider))
        _Item(
          Icons.download_for_offline_rounded,
          PlengoColors.blue,
          'المحتوى المحمّل',
          caption: 'التحميل دون اتصال والمساحة المستخدمة',
          onTap: () => context.go(Routes.offlineStorage),
        ),
      _Item(
        Icons.notifications_rounded,
        PlengoColors.orange,
        'الإشعارات والهدف اليومي',
        onTap: () => context.go(Routes.notificationSettings),
      ),
      _Item(
        Icons.school_rounded,
        PlengoColors.pink,
        'المرحلة التعليمية',
        caption: levelName,
        onTap: () => context.go(Routes.placement),
      ),
      if (ref.watch(teacherFollowingEnabledProvider))
        _Item(
          Icons.groups_rounded,
          PlengoColors.pink,
          'المدرسون الذين أتابعهم',
          onTap: () => context.go(Routes.following),
        ),
      _Item(Icons.devices_rounded, PlengoColors.blue, 'الأجهزة المتصلة', onTap: () => context.go(Routes.sessions)),
    ];
    final legal = <_Item>[
      _Item(Icons.privacy_tip_rounded, PlengoColors.blue, 'سياسة الخصوصية', onTap: () => context.push(Routes.privacy)),
      _Item(Icons.gavel_rounded, PlengoColors.blue, 'شروط الاستخدام', onTap: () => context.push(Routes.terms)),
      _Item(
        Icons.description_rounded,
        PlengoColors.blue,
        'تراخيص البرمجيات والخطوط',
        onTap: () => showLicensePage(context: context, applicationName: 'Plengo'),
      ),
    ];
    final danger = <_Item>[
      _Item(
        Icons.logout_rounded,
        PlengoColors.red,
        'تسجيل الخروج',
        danger: true,
        onTap: () => ref.read(authControllerProvider.notifier).logout(),
      ),
      _Item(
        Icons.delete_forever_rounded,
        PlengoColors.red,
        'حذف الحساب',
        caption: 'يطلب كلمة المرور ويشرح ما سيُحذف',
        danger: true,
        onTap: () => showDeleteAccountSheet(context),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('حسابي')),
      body: ContentWidth(
        child: ListView(
          padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 4, PlengoSpace.screen, 28),
          children: [
            if (me != null) ...[_ProfileCard(me: me), const SizedBox(height: PlengoSpace.section)],
            PlengoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Semantics(
                    header: true,
                    child: Text('المظهر', style: PlengoType.rowTitle.copyWith(color: context.surface.ink)),
                  ),
                  const SizedBox(height: 10),
                  SegmentedControl<ThemeMode>(
                    segments: const [
                      PlengoOption(ThemeMode.system, 'تلقائي', semanticsLabel: 'المظهر: تلقائي'),
                      PlengoOption(ThemeMode.light, 'فاتح', semanticsLabel: 'المظهر: فاتح'),
                      PlengoOption(ThemeMode.dark, 'داكن', semanticsLabel: 'المظهر: داكن'),
                    ],
                    selected: appearance.themeMode,
                    onChanged: appearanceCtl.setThemeMode,
                  ),
                  const SizedBox(height: 10),
                  // Each label is drawn at the size it selects.
                  SegmentedControl<int>(
                    segments: const [
                      PlengoOption(
                        0,
                        'خط صغير',
                        semanticsLabel: 'حجم الخط: صغير',
                        child: Text('خط صغير', style: TextStyle(fontSize: 12)),
                      ),
                      PlengoOption(
                        1,
                        'عادي',
                        semanticsLabel: 'حجم الخط: عادي',
                        child: Text('عادي', style: TextStyle(fontSize: 14)),
                      ),
                      PlengoOption(
                        2,
                        'كبير',
                        semanticsLabel: 'حجم الخط: كبير',
                        child: Text('كبير', style: TextStyle(fontSize: 17)),
                      ),
                    ],
                    selected: appearance.fontStep,
                    onChanged: appearanceCtl.setFontStep,
                  ),
                ],
              ),
            ),
            const SizedBox(height: PlengoSpace.section),
            _Group(items: settings),
            const SizedBox(height: PlengoSpace.section),
            _Group(items: legal),
            const SizedBox(height: PlengoSpace.section),
            _Group(items: danger),
          ],
        ),
      ),
    );
  }
}

class _Item {
  const _Item(this.icon, this.hue, this.title, {required this.onTap, this.caption, this.danger = false});

  final IconData icon;
  final PlengoHue hue;
  final String title;
  final String? caption;
  final VoidCallback onTap;

  /// Red title and no chevron (sign out, delete).
  final bool danger;
}

/// A card of flat rows with soft icon tiles and dividers between them.
class _Group extends StatelessWidget {
  const _Group({required this.items});

  final List<_Item> items;

  @override
  Widget build(BuildContext context) {
    final red = fieldErrorColor(context.surface);
    return PlengoCard(
      padding: const EdgeInsetsDirectional.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          for (final (i, item) in items.indexed)
            ListRow(
              flat: true,
              showDivider: i < items.length - 1,
              title: item.title,
              caption: item.caption,
              titleColor: item.danger ? red : null,
              leading: SubjectIconTile(icon: item.icon, hue: item.hue, size: 40, soft: true),
              trailing: item.danger ? const SizedBox.shrink() : null,
              onTap: item.onTap,
            ),
        ],
      ),
    );
  }
}

/// Yellow-soft header: avatar with a camera button, name and the email (LTR).
class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.me});

  final Me me;

  @override
  Widget build(BuildContext context) {
    return PlengoCard(
      color: PlengoColors.yellow.soft,
      child: Row(
        children: [
          _AvatarButton(me: me),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(me.fullName, style: PlengoType.section.copyWith(color: PlengoColors.ink)),
                Text(
                  me.email,
                  textDirection: TextDirection.ltr,
                  textAlign: TextAlign.right,
                  style: PlengoType.caption.copyWith(color: PlengoColors.yellow.ink, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Profile photo with a camera button: choose a new one (uploaded, processed to 400 px, then attached).
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
  Widget build(BuildContext context) {
    final onTap = _busy ? null : _change;
    return SizedBox(
      width: 84,
      height: 76,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          PositionedDirectional(
            top: 0,
            start: 0,
            child: SizedBox.square(
              dimension: 68,
              child: Center(
                child: _busy
                    ? const SizedBox.square(dimension: 28, child: CircularProgressIndicator(strokeWidth: 3))
                    : NetworkAvatar(url: widget.me.avatarUrl, name: widget.me.fullName, radius: 34),
              ),
            ),
          ),
          PositionedDirectional(
            bottom: -8,
            end: -4,
            child: Semantics(
              container: true,
              button: true,
              label: 'تغيير الصورة الشخصية',
              excludeSemantics: true,
              onTap: onTap,
              child: Material(
                color: Colors.white,
                shape: const CircleBorder(),
                elevation: 1,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onTap,
                  child: const SizedBox.square(
                    dimension: 48,
                    child: Icon(Icons.photo_camera_rounded, size: 22, color: PlengoColors.ink),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens the account-deletion sheet (spec §33).
Future<void> showDeleteAccountSheet(BuildContext context) =>
    showPlengoSheet<void>(context: context, useRootNavigator: true, builder: (_) => const DeleteAccountDialog());

/// Account deletion (spec §33): explains what is removed and asks for the password. Shown in a sheet.
class DeleteAccountDialog extends ConsumerStatefulWidget {
  const DeleteAccountDialog({super.key});

  @override
  ConsumerState<DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends ConsumerState<DeleteAccountDialog> {
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount(_password.text);
      if (mounted) Navigator.of(context).pop();
    } on ApiException catch (e) {
      setState(() => _error = e.code == 'AUTH_INVALID_CREDENTIALS' ? 'كلمة المرور غير صحيحة' : e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final bad = _error != null;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(PlengoRadius.input),
      borderSide: BorderSide(color: c, width: 2),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Center(
          child: StateIllustration(icon: Icons.delete_forever_rounded, hue: PlengoColors.red, size: 88),
        ),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            'حذف الحساب نهائياً',
            textAlign: TextAlign.center,
            style: PlengoType.section.copyWith(color: s.ink),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'سيُحذف اسمك وبريدك وصورتك ومجموعات بطاقاتك الخاصة ومحفوظاتك، وتُلغى صلاحيات الوصول '
          'بما فيها المفعّلة بالكوبونات، ويُسجَّل خروجك من كل الأجهزة. تبقى إحصاءات الإجابات '
          'دون أي بيانات تعرّف بك. لا يمكن التراجع عن هذه الخطوة.',
          style: PlengoType.sub.copyWith(color: s.mute),
        ),
        const SizedBox(height: 16),
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('أدخل كلمة المرور للتأكيد', style: PlengoType.rowTitle.copyWith(fontSize: 14, color: s.ink)),
              const SizedBox(height: 6),
              TextField(
                key: const Key('delete.password'),
                controller: _password,
                obscureText: true,
                enabled: !_busy,
                textDirection: TextDirection.ltr,
                autofillHints: const [AutofillHints.password],
                style: PlengoType.body.copyWith(color: bad ? PlengoColors.ink : s.ink, height: 1.3),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: bad ? PlengoColors.red.soft : s.card,
                  enabledBorder: border(bad ? PlengoColors.redStrong : s.line),
                  focusedBorder: border(bad ? PlengoColors.redStrong : s.action),
                  disabledBorder: border(s.line),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ],
          ),
        ),
        if (_error != null) FieldErrorText(message: _error!),
        const SizedBox(height: 16),
        PlengoButton(
          label: _busy ? 'جارٍ الحذف…' : 'حذف الحساب',
          variant: PlengoButtonVariant.danger,
          icon: Icons.delete_forever_rounded,
          onPressed: _busy || _password.text.isEmpty ? null : _delete,
        ),
        const SizedBox(height: 4),
        PlengoButton(
          label: 'إلغاء',
          variant: PlengoButtonVariant.ghost,
          onPressed: _busy ? null : () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}
