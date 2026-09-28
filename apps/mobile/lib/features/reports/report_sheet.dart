import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';

/// Whether content reports are on (remote flag, §10.2); on when the config is unknown.
final contentReportsEnabledProvider = Provider<bool>(
  (ref) => ref.watch(remoteConfigProvider).value?.features.contentReports ?? true,
);

class ReportRepository {
  ReportRepository(this.api);

  final PlengoApi api;

  Future<Report> create(ReportItemType type, String itemId, ReportReason reason, String? note) => guardApi(
    () async => (await api.reports.createReport(
      body: CreateReportRequest(itemType: type, itemId: itemId, reason: reason, note: note),
    )).data,
  );
}

final reportRepositoryProvider = Provider<ReportRepository>(
  (ref) => ReportRepository(ref.watch(apiClientProvider).api),
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
  final sent = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _ReportSheet(type: type, itemId: itemId),
  );
  if (sent == true && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('شكراً، وصلنا بلاغك وسنراجعه')));
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
      await ref.read(reportRepositoryProvider).create(widget.type, widget.itemId, _reason!, note.isEmpty ? null : note);
      if (mounted) Navigator.pop(context, true);
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
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('إبلاغ عن مشكلة', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            RadioGroup<ReportReason>(
              groupValue: _reason,
              onChanged: (v) => setState(() => _reason = v),
              child: Column(
                children: [for (final e in reasons) RadioListTile<ReportReason>(value: e.key, title: Text(e.value))],
              ),
            ),
            TextField(
              key: const Key('report-note'),
              controller: _note,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
            ),
            if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
            FilledButton(onPressed: _reason == null || _sending ? null : _send, child: const Text('إرسال البلاغ')),
          ],
        ),
      ),
    );
  }
}

/// Flag icon that opens [showReportSheet]; hidden when reports are off.
class ReportButton extends ConsumerWidget {
  const ReportButton({super.key, required this.type, required this.id});

  final ReportItemType type;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(contentReportsEnabledProvider)) return const SizedBox.shrink();
    return IconButton(
      tooltip: 'إبلاغ عن مشكلة',
      icon: const Icon(Icons.outlined_flag),
      onPressed: () => showReportSheet(context, ref, type, id),
    );
  }
}
