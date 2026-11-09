import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../core/db/app_database.dart';
import '../../shared/ui/ui.dart';

/// Whether content reports are on (remote flag, §10.2); on when the config is unknown.
final contentReportsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(remoteConfigProvider).value?.features.contentReports ?? true,
);

/// Reports go to the server; without a connection they wait on the device and are sent later
/// (spec §22.7). Returns null when queued.
class ReportRepository {
  ReportRepository(this.api, [this.db]);

  final PlengoApi api;
  final AppDatabase? db;
  static const queueKey = 'reports.queue';

  Future<Report?> create(ReportItemType type, String itemId, ReportReason reason, String? note) async {
    final body = CreateReportRequest(itemType: type, itemId: itemId, reason: reason, note: note);
    try {
      return await guardApi(() async => (await api.reports.createReport(body: body)).data);
    } on ApiException catch (e) {
      if (e.code != 'NETWORK_ERROR' || db == null) rethrow;
      await db!.setValue(queueKey, jsonEncode([...await _queued(), body]));
      return null;
    }
  }

  Future<List<Object?>> _queued() async => (jsonDecode(await db?.getValue(queueKey) ?? '[]') as List).cast<Object?>();

  /// Sends queued reports; keeps them while still offline. Refused ones (e.g. removed content) are dropped.
  Future<int> flush() async {
    final queued = await _queued();
    var sent = 0;
    for (final (i, item) in queued.indexed) {
      try {
        await guardApi(
          () => api.reports.createReport(body: CreateReportRequest.fromJson(item! as Map<String, Object?>)),
        );
        sent++;
      } on ApiException catch (e) {
        if (e.code == 'NETWORK_ERROR') {
          await db!.setValue(queueKey, jsonEncode(queued.sublist(i)));
          return sent;
        }
      }
    }
    if (queued.isNotEmpty) await db?.setValue(queueKey, '[]');
    return sent;
  }
}

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(apiClientProvider).api, ref.watch(databaseProvider)),
);

const reportReasons = {
  ReportReason.wrongAnswer: 'الإجابة خاطئة',
  ReportReason.typo: 'خطأ إملائي',
  ReportReason.unclear: 'غير واضح',
  ReportReason.imageProblem: 'مشكلة في الصورة',
  ReportReason.other: 'سبب آخر',
};

/// "إبلاغ عن مشكلة" (spec §21) on a question or an official card.
Future<void> showReportSheet(BuildContext context, WidgetRef ref, ReportItemType type, String itemId) async {
  final sent = await showPlengoSheet<bool>(
    context: context,
    title: 'إبلاغ عن مشكلة',
    builder: (_) => _ReportSheet(type: type, itemId: itemId),
  );
  if (sent != null && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(sent ? 'شكراً، وصلنا بلاغك وسنراجعه' : 'أنت غير متصل، سيُرسل بلاغك عند الاتصال')),
    );
  }
}

class _ReportSheet extends ConsumerStatefulWidget {
  const _ReportSheet({required this.type, required this.itemId});

  final ReportItemType type;
  final String itemId;

  @override
  ConsumerState<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<_ReportSheet> {
  ReportReason? _reason;
  final _note = TextEditingController();
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => (_sending = true, _error = null));
    try {
      final note = _note.text.trim();
      final report = await ref
          .read(reportRepositoryProvider)
          .create(widget.type, widget.itemId, _reason!, note.isEmpty ? null : note);
      if (mounted) Navigator.pop(context, report != null);
    } on ApiException catch (e) {
      setState(() => (_sending = false, _error = e.message));
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only reasons that fit the item: official cards have no answer text to be wrong.
    final reasons = reportReasons.entries.where(
      (e) => widget.type == ReportItemType.question
          ? e.key != ReportReason.imageProblem
          : e.key != ReportReason.wrongAnswer,
    );
    final s = context.surface;
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(PlengoRadius.input),
      borderSide: BorderSide(color: c, width: 2),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          container: true,
          label: 'سبب البلاغ',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (i, e) in reasons.indexed) ...[
                if (i > 0) const SizedBox(height: 6),
                RadioRow(
                  title: e.value,
                  minHeight: 50,
                  selected: _reason == e.key,
                  onTap: _sending ? null : () => setState(() => _reason = e.key),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        TextField(
          key: const Key('report-note'),
          controller: _note,
          maxLength: 500,
          minLines: 1,
          maxLines: 3,
          style: PlengoType.body.copyWith(color: s.ink),
          decoration: InputDecoration(
            labelText: 'ملاحظة (اختياري)',
            hintText: 'اكتب التفاصيل إن أردت',
            floatingLabelBehavior: FloatingLabelBehavior.always,
            filled: true,
            fillColor: s.card,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: border(s.line),
            focusedBorder: border(s.action),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 4),
          Text(
            _error!,
            style: PlengoType.sub.copyWith(color: PlengoColors.red.ink, fontWeight: FontWeight.w700),
          ),
        ],
        const SizedBox(height: 8),
        PlengoButton(label: 'إرسال البلاغ', busy: _sending, onPressed: _reason == null || _sending ? null : _send),
      ],
    );
  }
}

/// Flag icon that opens [showReportSheet]; hidden when reports are off. [soft] draws the app-bar
/// square; inside the feedback panel it is a plain icon in the panel's ink.
class ReportButton extends ConsumerWidget {
  const ReportButton({super.key, required this.type, required this.id, this.soft = true, this.color});

  final ReportItemType type;
  final String id;
  final bool soft;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(contentReportsEnabledProvider)) return const SizedBox.shrink();
    return PlengoIconButton(
      tooltip: 'إبلاغ عن مشكلة',
      icon: Icons.flag_outlined,
      soft: soft,
      color: color,
      onPressed: () => showReportSheet(context, ref, type, id),
    );
  }
}
