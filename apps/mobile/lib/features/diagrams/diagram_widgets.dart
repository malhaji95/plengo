import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import '../../shared/ui/ui.dart';
import '../flashcards/card_face.dart' show cardImageBuilderProvider;

/// Diagram practice is online only.
const diagramsOfflineText = 'تحتاج إلى اتصال بالإنترنت';

/// The Arabic text of a failed diagram call: the offline line for network errors, else the server's.
String diagramErrorText(Object error) => switch (error) {
  ApiException(code: 'NETWORK_ERROR') => diagramsOfflineText,
  ApiException(:final message) => message,
  _ => ApiException.genericMessage,
};

bool isOfflineError(Object? error) => error is ApiException && error.code == 'NETWORK_ERROR';

/// The three steps of the flow (الاختيار · التدريبات · النتيجة) with the current one in blue.
class DiagramSteps extends StatelessWidget {
  const DiagramSteps({super.key, required this.current});

  /// 0 setup, 1 practice, 2 results.
  final int current;

  static const labels = ['الاختيار', 'التدريبات', 'النتيجة'];

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    Widget line(bool show, bool done) =>
        Container(height: 2, color: !show ? Colors.transparent : (done ? s.action : s.line));
    return Semantics(
      label: 'الخطوة ${current + 1} من 3: ${labels[current]}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, label) in labels.indexed)
            Expanded(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(child: line(i > 0, i <= current)),
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(shape: BoxShape.circle, color: i <= current ? s.action : s.track),
                        child: i < current
                            ? Icon(Icons.check_rounded, size: 16, color: s.onAction)
                            : Text(
                                '${i + 1}',
                                textScaler: TextScaler.noScaling,
                                style: PlengoType.chip.copyWith(color: i <= current ? s.onAction : s.mute),
                              ),
                      ),
                      Expanded(child: line(i < labels.length - 1, i < current)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: PlengoType.caption.copyWith(
                        color: i == current ? s.ink : s.mute,
                        fontWeight: i == current ? FontWeight.w700 : FontWeight.w400,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A numbered marker (the label number in a blue circle).
class DiagramMarker extends StatelessWidget {
  const DiagramMarker({super.key, required this.number, this.size = 26, this.hue});

  final int number;
  final double size;

  /// Green / red after a check; blue before.
  final PlengoHue? hue;

  @override
  Widget build(BuildContext context) {
    final h = hue ?? PlengoColors.blue;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: h.fill,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
      child: FittedBox(
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: Text(
            '$number',
            textScaler: TextScaler.noScaling,
            style: PlengoType.chip.copyWith(color: h.onFill, fontSize: 13),
          ),
        ),
      ),
    );
  }
}

/// The diagram image, pinch-to-zoom, with the numbered markers drawn where the admin placed them
/// (x/y are fractions of the image). Images without stored dimensions are shown 4:3.
class DiagramImageView extends ConsumerWidget {
  const DiagramImageView({super.key, required this.diagram, this.results, this.maxHeight = 340});

  final PracticeDiagram diagram;

  /// After a check: markers turn green / red.
  final Map<int, bool>? results;
  final double maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = context.surface;
    final img = diagram.image;
    final w = img.width, h = img.height;
    final ratio = w != null && h != null && w > 0 && h > 0 ? w / h : 4 / 3;
    final build = ref.watch(cardImageBuilderProvider);
    return Semantics(
      image: true,
      label: 'رسمة: ${diagram.titleAr}',
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(PlengoRadius.card),
          border: Border.all(color: s.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: InteractiveViewer(
            key: const Key('diagram.zoom'),
            maxScale: 4,
            child: Center(
              child: AspectRatio(
                aspectRatio: ratio,
                child: LayoutBuilder(
                  builder: (context, box) => Stack(
                    fit: StackFit.expand,
                    children: [
                      build(context, img),
                      for (final l in diagram.labels)
                        if (l.x != null && l.y != null)
                          Positioned(
                            left: (l.x!.toDouble().clamp(0, 1) * box.maxWidth) - 13,
                            top: (l.y!.toDouble().clamp(0, 1) * box.maxHeight) - 13,
                            child: ExcludeSemantics(
                              child: DiagramMarker(
                                number: l.number,
                                hue: switch (results?[l.number]) {
                                  true => PlengoColors.green,
                                  false => PlengoColors.red,
                                  null => null,
                                },
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One label's verdict after a check: ✓ green or ✗ red, the student's answer and, when wrong, the
/// accepted answer.
class DiagramLabelVerdict extends StatelessWidget {
  const DiagramLabelVerdict({super.key, required this.result, this.showAnswer = true});

  final DiagramLabelResult result;

  /// Shows the student's answer (results list); the session shows it in the field instead.
  final bool showAnswer;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final hue = result.isCorrect ? PlengoColors.green : PlengoColors.red;
    final answer = result.answer?.trim();
    final accepted = result.acceptedAnswers.join(' / ');
    return Semantics(
      container: true,
      label:
          'الجزء ${result.number}: ${result.isCorrect ? 'صحيحة' : 'خاطئة'}'
          '${showAnswer ? '، إجابتك: ${answer == null || answer.isEmpty ? 'لا شيء' : answer}' : ''}'
          '${result.isCorrect ? '' : '، الإجابة الصحيحة: $accepted'}',
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DiagramMarker(number: result.number, hue: hue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showAnswer)
                  Text(
                    answer == null || answer.isEmpty ? 'لم تكتب إجابة' : answer,
                    style: PlengoType.rowTitle.copyWith(
                      color: answer == null || answer.isEmpty ? s.mute : s.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (!result.isCorrect)
                  Text(
                    'الإجابة الصحيحة: $accepted',
                    style: PlengoType.sub.copyWith(color: s.isDark ? PlengoColors.green.base : PlengoColors.green.ink),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            result.isCorrect ? Icons.check_rounded : Icons.close_rounded,
            color: s.isDark ? hue.base : hue.ink,
            size: 22,
          ),
        ],
      ),
    );
  }
}
