import 'package:flutter/material.dart';

/// Phone layout below this width; above it, a navigation rail and wider layouts (spec §24).
const double kWideBreakpoint = 600;

/// Maximum content width of reading, study and quiz screens on wide screens (spec §24).
const double kContentMaxWidth = 720;

/// Centres [child] and caps it at [kContentMaxWidth].
class ContentWidth extends StatelessWidget {
  const ContentWidth({super.key, required this.child, this.maxWidth = kContentMaxWidth});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// A list on phones and a multi-column grid on wide screens (spec §24). Rows keep the height of
/// their tallest item so cards of different lengths line up.
class ResponsiveList extends StatelessWidget {
  const ResponsiveList({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 24),
    this.spacing = 8,
    this.minColumnWidth = 340,
    this.maxColumns = 3,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final EdgeInsets padding;
  final double spacing;
  final double minColumnWidth;
  final int maxColumns;

  /// Columns for a given width; one below [kWideBreakpoint].
  static int columnsFor(double width, {double minColumnWidth = 340, int maxColumns = 3}) =>
      width < kWideBreakpoint ? 1 : (width / minColumnWidth).floor().clamp(1, maxColumns);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = columnsFor(
          constraints.maxWidth - padding.horizontal,
          minColumnWidth: minColumnWidth,
          maxColumns: maxColumns,
        );
        if (columns == 1) {
          return ListView.separated(
            padding: padding,
            itemCount: itemCount,
            separatorBuilder: (_, _) => SizedBox(height: spacing),
            itemBuilder: itemBuilder,
          );
        }
        final rows = (itemCount / columns).ceil();
        return ListView.separated(
          padding: padding,
          itemCount: rows,
          separatorBuilder: (_, _) => SizedBox(height: spacing),
          itemBuilder: (context, r) => IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var c = 0; c < columns; c++) ...[
                  if (c > 0) SizedBox(width: spacing),
                  Expanded(
                    child: r * columns + c < itemCount ? itemBuilder(context, r * columns + c) : const SizedBox(),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
