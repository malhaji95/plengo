import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/responsive.dart';

enum LegalDocument {
  privacy('assets/legal/privacy.md', 'سياسة الخصوصية'),
  terms('assets/legal/terms.md', 'شروط الاستخدام');

  const LegalDocument(this.asset, this.title);

  final String asset;
  final String title;
}

/// Loads a bundled legal text; replaced in tests.
final legalTextProvider = FutureProvider.family<String, LegalDocument>((ref, doc) => rootBundle.loadString(doc.asset));

/// Blocks of the small Markdown subset the legal texts use: `#`/`##` headings, `- ` items, paragraphs.
sealed class LegalBlock {
  const LegalBlock(this.text);
  final String text;
}

class LegalHeading extends LegalBlock {
  const LegalHeading(super.text, {required this.level});
  final int level;
}

class LegalItem extends LegalBlock {
  const LegalItem(super.text);
}

class LegalParagraph extends LegalBlock {
  const LegalParagraph(super.text);
}

List<LegalBlock> parseLegal(String source) {
  final blocks = <LegalBlock>[];
  for (final raw in source.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('## ')) {
      blocks.add(LegalHeading(line.substring(3), level: 2));
    } else if (line.startsWith('# ')) {
      blocks.add(LegalHeading(line.substring(2), level: 1));
    } else if (line.startsWith('- ')) {
      blocks.add(LegalItem(line.substring(2)));
    } else {
      blocks.add(LegalParagraph(line));
    }
  }
  return blocks;
}

/// Privacy policy and terms (spec §33, §44), readable signed in or out.
class LegalScreen extends ConsumerWidget {
  const LegalScreen({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = ref.watch(legalTextProvider(document));
    final s = context.surface;
    final body = PlengoType.sub.copyWith(fontSize: 15, color: s.ink);
    return Scaffold(
      appBar: AppBar(
        // Opened directly (store listing link) there is nothing to go back to.
        leading: Navigator.canPop(context) ? const PlengoBackButton() : null,
        leadingWidth: kPlengoLeadingWidth,
        automaticallyImplyLeading: false,
        title: Text(document.title),
      ),
      body: ContentWidth(
        child: AsyncView(
          value: text,
          onRetry: () => ref.invalidate(legalTextProvider(document)),
          data: (source) => ListView(
            padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 8, PlengoSpace.screen, 32),
            children: [
              for (final b in parseLegal(source))
                switch (b) {
                  // The page title is already in the app bar.
                  LegalHeading(level: 1) => const SizedBox.shrink(),
                  LegalHeading() => Padding(
                    padding: const EdgeInsetsDirectional.only(top: 20, bottom: 8),
                    child: Semantics(
                      header: true,
                      child: Text(b.text, style: PlengoType.section.copyWith(color: s.ink)),
                    ),
                  ),
                  LegalItem() => Padding(
                    padding: const EdgeInsetsDirectional.only(start: 4, bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsetsDirectional.only(top: 10, end: 10),
                          child: ExcludeSemantics(
                            child: Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(color: s.action, shape: BoxShape.circle),
                            ),
                          ),
                        ),
                        Expanded(child: Text(b.text, style: body)),
                      ],
                    ),
                  ),
                  LegalParagraph() => Padding(
                    padding: const EdgeInsetsDirectional.only(bottom: 10),
                    child: Text(b.text, style: body),
                  ),
                },
            ],
          ),
        ),
      ),
    );
  }
}

/// "بإنشاء الحساب فإنك توافق على الشروط وسياسة الخصوصية" with both links (48 dp targets).
class LegalConsentText extends StatelessWidget {
  const LegalConsentText({super.key, required this.onOpen});

  final void Function(LegalDocument) onOpen;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final plain = PlengoType.caption.copyWith(color: s.mute);
    Widget link(String label, LegalDocument doc) => Semantics(
      container: true,
      link: true,
      child: InkWell(
        onTap: () => onOpen(doc),
        borderRadius: BorderRadius.circular(8),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Center(
            widthFactor: 1,
            child: Text(
              label,
              style: plain.copyWith(color: s.action, fontWeight: FontWeight.w700, decoration: TextDecoration.underline),
            ),
          ),
        ),
      ),
    );
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text('بإنشاء الحساب فإنك توافق على ', style: plain),
        link('شروط الاستخدام', LegalDocument.terms),
        Text(' و', style: plain),
        link('سياسة الخصوصية', LegalDocument.privacy),
      ],
    );
  }
}
