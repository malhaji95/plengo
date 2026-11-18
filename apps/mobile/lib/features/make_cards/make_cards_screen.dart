import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../core/api/generated/export.dart';
import '../../core/content/my_decks_store.dart';
import '../../shared/ui/ui.dart';
import '../../shared/widgets/async_view.dart';
import '../../shared/widgets/responsive.dart';
import '../flashcards/decks_screen.dart' show cardCountLabel;
import '../flashcards/flashcard_ui.dart';
import '../my_decks/my_decks_providers.dart';
import '../plengo_cards/place_header.dart';
import '../shell/app_drawer.dart';
import 'card_templates.dart';
import 'make_cards_providers.dart';
import 'make_cards_widgets.dart';

/// Where a group's pages live: `/make-cards/groups/<id>` and its sub-pages.
String groupLocation(String deckId, [String? sub]) =>
    '${Routes.makeCardsGroups}/$deckId${sub == null ? '' : '/$sub'}';

/// اصنع بطاقاتك الخاصة (v3 §7) at [Routes.makeCards]: choose a subject of the student's level, then a
/// frame, then «ابدأ الإنشاء» opens the creation flow. «مجموعاتي» lists what the student made.
class MakeCardsScreen extends ConsumerStatefulWidget {
  const MakeCardsScreen({super.key, this.subjectId});

  /// Preselects a subject (e.g. from «مجموعة جديدة» on مجموعاتي of one subject).
  final String? subjectId;

  @override
  ConsumerState<MakeCardsScreen> createState() => _MakeCardsScreenState();
}

class _MakeCardsScreenState extends ConsumerState<MakeCardsScreen> {
  late String? _subjectId = widget.subjectId;
  String? _templateKey;

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(studentSubjectsProvider);
    final templates = availableTemplates(ref);
    final template = _templateKey ?? templates.first.key;
    final menu = DrawerMenuButton.leadingOf(context);
    final s = context.surface;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: menu,
        leadingWidth: kPlengoLeadingWidth,
        titleSpacing: menu == null ? PlengoSpace.screen : null,
        title: const Text('اصنع بطاقاتك الخاصة'),
      ),
      body: ContentWidth(
        child: AsyncView(
          value: subjects,
          onRetry: () => ref.invalidate(studentSubjectsProvider),
          data: (list) {
            final chosen = list.any((x) => x.id == _subjectId) ? _subjectId : list.firstOrNull?.id;
            final subjectName = chosen == null ? null : subjectNameOf(list, chosen);
            return ListView(
              padding: const EdgeInsetsDirectional.only(bottom: 28),
              children: [
                const Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 4, PlengoSpace.screen, 4),
                  child: PlaceHeader(
                    title: 'اصنع بطاقاتك الخاصة',
                    subtitle: 'أنشئ فلاش كاردز تناسب أسلوبك في المراجعة',
                    icon: Icons.add_card_rounded,
                    hue: PlengoColors.pink,
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 8, PlengoSpace.screen, 0),
                  child: ListRow(
                    key: const Key('makeCards.myGroups'),
                    title: 'مجموعاتي',
                    caption: 'مجموعات الفلاش كاردز التي أنشأتها',
                    icon: Icons.collections_bookmark_rounded,
                    hue: PlengoColors.blue,
                    onTap: () => context.go(Routes.makeCardsGroups),
                  ),
                ),
                if (list.isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsetsDirectional.symmetric(horizontal: PlengoSpace.screen),
                    child: SectionHeader('اختر المادة'),
                  ),
                  SubjectCarousel(
                    subjects: list,
                    selected: chosen,
                    onSelected: (id) => setState(() => _subjectId = id),
                  ),
                ] else
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 16, PlengoSpace.screen, 0),
                    child: Text(
                      'اختر صفّك من حسابك لتظهر موادك؛ يمكنك الآن إنشاء مجموعة بلا مادة.',
                      style: PlengoType.sub.copyWith(color: s.mute),
                    ),
                  ),
                const Padding(
                  padding: EdgeInsetsDirectional.symmetric(horizontal: PlengoSpace.screen),
                  child: SectionHeader('اختر القالب التصميمي', bottom: 0),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 0, PlengoSpace.screen, 10),
                  child: Text(
                    subjectName == null
                        ? 'اختر التصميم الذي يعجبك لبطاقات مجموعتك'
                        : 'اختر التصميم الذي يعجبك لبطاقات مجموعتك في $subjectName',
                    style: PlengoType.caption.copyWith(color: s.mute),
                  ),
                ),
                TemplatePicker(
                  templates: templates,
                  selected: template,
                  onSelected: (k) => setState(() => _templateKey = k),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 20, PlengoSpace.screen, 0),
                  child: PlengoButton(
                    key: const Key('makeCards.start'),
                    label: 'ابدأ الإنشاء',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => context.go(
                      Uri(
                        path: Routes.makeCardsNew,
                        queryParameters: {'subjectId': ?chosen, 'template': template},
                      ).toString(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// مجموعاتي (v3 §7) at [Routes.makeCardsGroups]: the student's groups by subject (a pill per
/// subject, «الكل» first), each with «مراجعة» and «تعديل»; a tap opens the group page.
class MyGroupsScreen extends ConsumerStatefulWidget {
  const MyGroupsScreen({super.key, this.subjectId});

  final String? subjectId;

  @override
  ConsumerState<MyGroupsScreen> createState() => _MyGroupsScreenState();
}

class _MyGroupsScreenState extends ConsumerState<MyGroupsScreen> {
  late String? _subjectId = widget.subjectId;

  @override
  void initState() {
    super.initState();
    // Bring other devices' groups in.
    Future.microtask(() => ref.read(myDecksSyncProvider).syncNow());
  }

  @override
  void didUpdateWidget(MyGroupsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.subjectId != widget.subjectId) _subjectId = widget.subjectId;
  }

  @override
  Widget build(BuildContext context) {
    listenForSyncNoticesOf(context, ref);
    final decks = ref.watch(myDecksProvider);
    final subjects = ref.watch(studentSubjectsProvider).value ?? const <CatalogSubject>[];
    return Scaffold(
      appBar: plengoAppBar(context, title: 'مجموعاتي'),
      body: ContentWidth(
        child: AsyncView(
          value: decks,
          onRetry: () => ref.invalidate(myDecksProvider),
          data: (all) {
            // A pill per subject that has groups, in the student's subject order; the linked subject too.
            final ids = <String?>{for (final d in all) d.deck.subjectId, ?_subjectId};
            final order = [for (final sub in subjects) sub.id];
            final pills = ids.toList()
              ..sort((a, b) {
                int rank(String? id) => id == null ? 1 << 20 : (order.contains(id) ? order.indexOf(id) : 1 << 19);
                return rank(a).compareTo(rank(b));
              });
            final groups = [
              for (final d in all)
                if (_subjectId == null || d.deck.subjectId == _subjectId) d,
            ];
            return ListView(
              padding: const EdgeInsetsDirectional.only(bottom: 28),
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 0, PlengoSpace.screen, 12),
                  child: Column(
                    children: [
                      const ExcludeSemantics(
                        child: CardStackArt(icon: Icons.school_rounded, hue: PlengoColors.blue),
                      ),
                      Text(
                        'مجموعات الفلاش كاردز التي أنشأتها',
                        textAlign: TextAlign.center,
                        style: PlengoType.sub.copyWith(color: context.surface.mute),
                      ),
                    ],
                  ),
                ),
                if (pills.length > 1 || _subjectId != null)
                  PillSelector<String?>(
                    key: const Key('groups.pills'),
                    options: [
                      const PlengoOption(null, 'الكل'),
                      for (final id in pills)
                        if (id != null) PlengoOption(id, subjectNameOf(subjects, id)),
                    ],
                    selected: _subjectId,
                    onSelected: (id) => setState(() => _subjectId = id),
                  ),
                const SizedBox(height: 14),
                if (groups.isEmpty)
                  PlengoEmptyState(
                    title: 'لا مجموعات بعد',
                    message: 'أنشئ مجموعتك الأولى من بطاقاتك الخاصة',
                    icon: Icons.add_card_rounded,
                    hue: PlengoColors.pink,
                    actionLabel: 'مجموعة جديدة',
                    onAction: () => _newGroup(context),
                  )
                else ...[
                  for (final g in groups)
                    Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        PlengoSpace.screen,
                        0,
                        PlengoSpace.screen,
                        PlengoSpace.listGap,
                      ),
                      child: GroupCard(group: g, subjectName: subjectNameOf(subjects, g.deck.subjectId)),
                    ),
                  Padding(
                    padding: const EdgeInsetsDirectional.fromSTEB(PlengoSpace.screen, 10, PlengoSpace.screen, 0),
                    child: PlengoButton(
                      key: const Key('groups.new'),
                      label: 'مجموعة جديدة',
                      icon: Icons.add_rounded,
                      onPressed: () => _newGroup(context),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  void _newGroup(BuildContext context) => context.go(
    Uri(path: Routes.makeCards, queryParameters: {'subjectId': ?_subjectId}).toString(),
  );
}

/// Shows the server's refusals from the last sync once (as on بطاقاتي).
void listenForSyncNoticesOf(BuildContext context, WidgetRef ref) {
  ref.listen(myDecksSyncNoticeProvider, (_, rejected) {
    if (rejected.isEmpty) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(rejectionMessage(rejected.first))));
    ref.read(myDecksSyncNoticeProvider.notifier).clear();
  });
}

/// One group in مجموعاتي: its subject tile, name and count, then «مراجعة» and «تعديل».
class GroupCard extends StatelessWidget {
  const GroupCard({super.key, required this.group, required this.subjectName});

  final DeckWithCount group;
  final String subjectName;

  @override
  Widget build(BuildContext context) {
    final s = context.surface;
    final d = group.deck;
    final hue = groupHue(d);
    return PlengoCard(
      key: Key('group.${d.id}'),
      padding: const EdgeInsetsDirectional.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            button: true,
            container: true,
            label: [d.name, subjectName, cardCountLabel(group.cardCount)].join('، '),
            excludeSemantics: true,
            onTap: () => context.push(groupLocation(d.id)),
            child: InkWell(
              borderRadius: BorderRadius.circular(PlengoRadius.iconTile),
              onTap: () => context.push(groupLocation(d.id)),
              child: Row(
                children: [
                  SubjectIconTile(icon: Icons.style_rounded, hue: hue, size: 44),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(d.name, style: PlengoType.rowTitle.copyWith(color: s.ink)),
                        Text(subjectName, style: PlengoType.caption.copyWith(color: s.mute)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  PlengoChip(label: cardCountLabel(group.cardCount), hue: hue, icon: Icons.style_outlined),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              PlengoButton(
                key: Key('group.${d.id}.review'),
                label: 'مراجعة',
                icon: Icons.play_arrow_rounded,
                size: PlengoButtonSize.small,
                onPressed: group.cardCount == 0 ? null : () => context.push('${Routes.myDeckStudy}/${d.id}/study'),
              ),
              PlengoButton(
                key: Key('group.${d.id}.edit'),
                label: 'تعديل',
                icon: Icons.edit_rounded,
                variant: PlengoButtonVariant.secondary,
                size: PlengoButtonSize.small,
                onPressed: () => context.push(groupLocation(d.id, 'edit')),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
