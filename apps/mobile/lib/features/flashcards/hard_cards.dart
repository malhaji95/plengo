import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'flashcard_providers.dart';

/// The ids of the official cards the student finds hard (v3 §8), from the SRS states on this device:
/// two or more lapses, or a low ease (see [SrsStore.hardCardIds]). The study controller invalidates it
/// after each rating and undo; the saved tab marks these cards «صعبة» and Home counts them.
final hardCardsProvider = FutureProvider.autoDispose<Set<String>>((ref) => ref.watch(srsStoreProvider).hardCardIds());
