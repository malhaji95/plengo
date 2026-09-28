import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
    final theme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(title: Text(document.title)),
      body: ContentWidth(
        child: AsyncView(
          value: text,
          onRetry: () => ref.invalidate(legalTextProvider(document)),
          data: (source) => ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              for (final b in parseLegal(source))
                switch (b) {
                  // The page title is already in the app bar.
                  LegalHeading(level: 1) => const SizedBox.shrink(),
                  LegalHeading() => Padding(
                    padding: const EdgeInsets.only(top: 20, bottom: 8),
                    child: Text(b.text, style: theme.titleMedium),
                  ),
                  LegalItem() => Padding(
                    padding: const EdgeInsetsDirectional.only(start: 8, bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('•  '),
                        Expanded(child: Text(b.text, style: theme.bodyMedium)),
                      ],
                    ),
                  ),
                  LegalParagraph() => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(b.text, style: theme.bodyMedium),
                  ),
                },
            ],
          ),
        ),
      ),
    );
  }
}

/// "بإنشاء الحساب فإنك توافق على الشروط وسياسة الخصوصية" with both links.
class LegalConsentText extends StatelessWidget {
  const LegalConsentText({super.key, required this.onOpen});

  final void Function(LegalDocument) onOpen;

  @override
  Widget build(BuildContext context) {
    final link = TextStyle(color: Theme.of(context).colorScheme.primary, decoration: TextDecoration.underline);
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        const Text('بإنشاء الحساب فإنك توافق على '),
        InkWell(
          onTap: () => onOpen(LegalDocument.terms),
          child: Text('شروط الاستخدام', style: link),
        ),
        const Text(' و'),
        InkWell(
          onTap: () => onOpen(LegalDocument.privacy),
          child: Text('سياسة الخصوصية', style: link),
        ),
      ],
    );
  }
}
