import '../../core/api/generated/export.dart';

/// Access dates are shown on the Damascus calendar (spec §8.2). Syria keeps UTC+3 all year, so a fixed
/// offset is exact and avoids shipping a time-zone database.
String damascusDate(String iso) {
  final d = DateTime.parse(iso).toUtc().add(const Duration(hours: 3));
  return '${d.year}/${d.month}/${d.day}';
}

/// "الفيزياء" for general subject content, "track · subject" for a teacher track.
String scopeTitle(AccessScope s) =>
    s.scopeType == AccessScopeScopeType.teacherTrack ? (s.trackTitleAr ?? s.subjectNameAr) : s.subjectNameAr;

String scopeSubtitle(AccessScope s) => s.scopeType == AccessScopeScopeType.teacherTrack
    ? '${s.teacherNameAr ?? ''} · ${s.subjectNameAr}'
    : 'المحتوى العام للمادة';

String termLabel({required bool isPermanent, String? expiresAt}) =>
    isPermanent ? 'وصول دائم' : 'حتى ${damascusDate(expiresAt!)}';
