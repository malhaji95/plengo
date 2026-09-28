import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../../core/api/generated/export.dart';
import 'bookmark_providers.dart';

/// Save / unsave an item (المحفوظات, spec §17).
class BookmarkButton extends ConsumerWidget {
  const BookmarkButton({super.key, required this.type, required this.id});

  final BookmarkItemType type;
  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(bookmarkKeysProvider).value?.contains(bookmarkKey(type, id)) ?? false;
    return IconButton(
      tooltip: saved ? 'إزالة من المحفوظات' : 'حفظ',
      icon: Icon(saved ? Icons.bookmark : Icons.bookmark_border),
      onPressed: () async {
        try {
          await ref.read(bookmarkKeysProvider.notifier).toggle(type, id);
        } on ApiException catch (e) {
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
        }
      },
    );
  }
}
