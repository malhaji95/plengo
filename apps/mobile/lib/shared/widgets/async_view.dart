import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/api/api_exception.dart';
import 'ui_kit.dart';

/// Loading spinner, Arabic error with retry, or the data view. [frame] wraps the loading and error
/// views when the data view brings its own scaffold.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.data, required this.onRetry, this.frame});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback onRetry;
  final Widget Function(Widget child)? frame;

  @override
  Widget build(BuildContext context) {
    final wrap = frame ?? (Widget w) => w;
    return value.when(
      data: data,
      loading: () => wrap(
        const Center(
          child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => wrap(
        Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SpotIcon(
                  e is ApiException && e.code == 'NETWORK_ERROR' ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
                  tint: BrandColors.tintRed,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(height: 16),
                Text(
                  e is ApiException ? e.message : ApiException.genericMessage,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة المحاولة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A friendly empty screen: illustration, the message, an optional hint and action.
class EmptyState extends StatelessWidget {
  const EmptyState(this.text, {super.key, this.icon = Icons.inbox_outlined, this.hint, this.action, this.onAction});

  final String text;
  final IconData icon;
  final String? hint;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SpotIcon(
              icon,
              tint: BrandColors.tintYellow,
              color: Theme.of(context).brightness == Brightness.dark ? null : BrandColors.ink,
            ),
            const SizedBox(height: 16),
            Text(this.text, textAlign: TextAlign.center, style: text.titleMedium),
            if (hint != null) ...[
              const SizedBox(height: 6),
              Text(
                hint!,
                textAlign: TextAlign.center,
                style: text.bodyMedium?.copyWith(color: muted),
              ),
            ],
            if (action != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(160, 48)),
                onPressed: onAction,
                child: Text(action!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
