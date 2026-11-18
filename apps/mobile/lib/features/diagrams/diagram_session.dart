import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../questions/question_view.dart' show InlineError;
import 'diagram_repository.dart';
import 'diagram_widgets.dart';

/// One run through a set of diagrams: for each, the image and a field per numbered label. With
/// [checkEach] every diagram is checked before moving on (✓ / ✗ and the accepted answer); otherwise
/// all are checked together at the end. Calls [onDone] with one result per diagram, in order.
class DiagramSession extends ConsumerStatefulWidget {
  const DiagramSession({
    super.key,
    required this.diagrams,
    required this.checkEach,
    required this.onDone,
    required this.onExit,
  });

  final List<PracticeDiagram> diagrams;
  final bool checkEach;
  final ValueChanged<List<DiagramCheckResult>> onDone;

  /// ✕ (after the exit sheet) and the system back.
  final VoidCallback onExit;

  @override
  ConsumerState<DiagramSession> createState() => _DiagramSessionState();
}

class _DiagramSessionState extends ConsumerState<DiagramSession> {
  int _index = 0;
  final _fields = <String, Map<int, TextEditingController>>{};
  final _results = <String, DiagramCheckResult>{};
  bool _busy = false;
  String? _error;

  PracticeDiagram get _d => widget.diagrams[_index];
  bool get _last => _index == widget.diagrams.length - 1;

  List<PracticeDiagramLabel> _labels(PracticeDiagram d) => [...d.labels]..sort((a, b) => a.number.compareTo(b.number));

  Map<int, TextEditingController> _controllers(PracticeDiagram d) =>
      _fields.putIfAbsent(d.id, () => {for (final l in d.labels) l.number: TextEditingController()});

  Map<int, String> _answers(PracticeDiagram d) => {
    for (final MapEntry(key: n, value: c) in _controllers(d).entries) n: c.text,
  };

  @override
  void dispose() {
    for (final m in _fields.values) {
      for (final c in m.values) {
        c.dispose();
      }
    }
    super.dispose();
  }

  Future<bool> _checkAll(Iterable<PracticeDiagram> diagrams) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final repo = ref.read(diagramRepositoryProvider);
      for (final d in diagrams) {
        if (_results.containsKey(d.id)) continue;
        final r = await repo.check(d.id, _answers(d));
        if (!mounted) return false;
        setState(() => _results[d.id] = r);
      }
      return true;
    } catch (e) {
      if (mounted) setState(() => _error = diagramErrorText(e));
      return false;
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _finish() => widget.onDone([for (final d in widget.diagrams) _results[d.id]!]);

  Future<void> _primary() async {
    FocusScope.of(context).unfocus();
    if (widget.checkEach) {
      if (!_results.containsKey(_d.id)) {
        await _checkAll([_d]);
        return;
      }
      if (_last) return _finish();
      setState(() => _index++);
      return;
    }
    if (!_last) {
      setState(() => _index++);
      return;
    }
    if (await _checkAll(widget.diagrams)) _finish();
  }

  Future<void> _exit() async {
    final stay = await showConfirmSheet(
      context,
      title: 'الخروج من التدريب؟',
      message: 'لن تُحفظ إجاباتك في هذه الرسومات.',
      icon: Icons.schema_rounded,
      hue: PlengoColors.green,
      primaryLabel: 'واصل التدريب',
      secondaryLabel: 'خروج',
    );
    if (stay == false && mounted) widget.onExit();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final d = _d;
    final result = _results[d.id];
    final verdicts = {for (final l in result?.labels ?? const <DiagramLabelResult>[]) l.number: l};
    final controllers = _controllers(d);
    final labels = _labels(d);
    final total = widget.diagrams.length;
    final checked = result != null;
    final label = switch ((widget.checkEach, checked, _last)) {
      (true, false, _) => 'تحقق',
      (true, true, false) => 'التالي',
      (true, true, true) => 'عرض النتيجة',
      (false, _, false) => 'التالي',
      (false, _, true) => 'إنهاء وتصحيح',
    };
    final icon = label == 'تحقق' || label == 'إنهاء وتصحيح' ? Icons.check_rounded : Icons.arrow_back_rounded;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exit();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(4, 8, 20, 4),
                child: Row(
                  children: [
                    PlengoCloseButton(key: const Key('diagrams.exit'), onPressed: _exit),
                    const SizedBox(width: 12),
                    Expanded(
                      child: PlengoProgressBar(
                        value: (_index + (checked || !widget.checkEach ? 1 : 0)) / total,
                        label: 'رسمة ${_index + 1} من $total',
                        color: PlengoColors.green.base,
                        compact: true,
                        labelBelow: true,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: ListView(
                      key: ValueKey('diagram.${d.id}'),
                      padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 16),
                      children: [
                        const DiagramSteps(current: 1),
                        const SizedBox(height: 16),
                        Text(d.titleAr, style: PlengoType.section.copyWith(color: s.ink)),
                        const SizedBox(height: 10),
                        DiagramImageView(
                          diagram: d,
                          results: result == null ? null : {for (final l in result.labels) l.number: l.isCorrect},
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'قرّب بإصبعين لتكبير الرسمة',
                          textAlign: TextAlign.center,
                          style: PlengoType.caption.copyWith(color: s.mute),
                        ),
                        const SizedBox(height: 12),
                        Text('اكتب اسم كل جزء بحسب رقمه:', style: PlengoType.rowTitle.copyWith(color: s.ink)),
                        const SizedBox(height: 10),
                        for (final (i, l) in labels.indexed) ...[
                          _LabelField(
                            number: l.number,
                            controller: controllers[l.number]!,
                            last: i == labels.length - 1,
                            verdict: verdicts[l.number],
                            enabled: !checked && !_busy,
                          ),
                          const SizedBox(height: 10),
                        ],
                        if (result != null) ...[
                          const SizedBox(height: 4),
                          _DiagramScoreLine(result: result),
                        ],
                        if (_error != null) ...[const SizedBox(height: 8), InlineError(_error)],
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(20, 8, 20, 12),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: PlengoButton(
                    key: const Key('diagrams.primary'),
                    label: label,
                    icon: icon,
                    busy: _busy,
                    onPressed: _busy ? null : _primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabelField extends StatelessWidget {
  const _LabelField({
    required this.number,
    required this.controller,
    required this.last,
    required this.verdict,
    required this.enabled,
  });

  final int number;
  final TextEditingController controller;
  final bool last;
  final DiagramLabelResult? verdict;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final v = verdict;
    final hue = v == null ? null : (v.isCorrect ? PlengoColors.green : PlengoColors.red);
    OutlineInputBorder border(Color c) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(PlengoRadius.input),
      borderSide: BorderSide(color: c, width: 2),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            DiagramMarker(number: number, hue: hue, size: 30),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                key: Key('diagrams.answer.$number'),
                controller: controller,
                readOnly: !enabled,
                textInputAction: last ? TextInputAction.done : TextInputAction.next,
                textDirection: TextDirection.rtl,
                style: PlengoType.body.copyWith(color: s.ink),
                decoration: InputDecoration(
                  hintText: 'اكتب الإجابة…',
                  isDense: true,
                  fillColor: hue == null ? null : (s.isDark ? hue.base.withValues(alpha: 0.14) : hue.soft),
                  enabledBorder: hue == null ? null : border(hue.base),
                  focusedBorder: hue == null ? null : border(hue.base),
                  suffixIcon: v == null
                      ? null
                      : Icon(
                          v.isCorrect ? Icons.check_rounded : Icons.close_rounded,
                          color: s.isDark ? hue!.base : hue!.ink,
                          semanticLabel: v.isCorrect ? 'صحيحة' : 'خاطئة',
                        ),
                ),
              ),
            ),
          ],
        ),
        if (v != null && !v.isCorrect)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 40, top: 6),
            child: Container(
              padding: const EdgeInsetsDirectional.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: s.isDark ? PlengoColors.green.base.withValues(alpha: 0.14) : PlengoColors.green.soft,
                borderRadius: BorderRadius.circular(PlengoRadius.input),
              ),
              child: Text(
                'الإجابة الصحيحة للرقم $number: ${v.acceptedAnswers.join(' / ')}',
                style: PlengoType.sub.copyWith(
                  color: s.isDark ? PlengoColors.green.base : PlengoColors.green.ink,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _DiagramScoreLine extends StatelessWidget {
  const _DiagramScoreLine({required this.result});

  final DiagramCheckResult result;

  @override
  Widget build(BuildContext context) {
    final all = result.correctCount == result.totalCount;
    return Semantics(
      liveRegion: true,
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: PlengoChip(
          label: '${all ? 'أحسنت! ' : ''}${result.correctCount} من ${result.totalCount} صحيحة',
          hue: all ? PlengoColors.green : PlengoColors.orange,
          icon: all ? Icons.check_circle_rounded : Icons.info_outline_rounded,
        ),
      ),
    );
  }
}
