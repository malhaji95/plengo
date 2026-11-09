import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api/api_exception.dart';
import '../ui/states.dart';
import '../ui/tokens.dart';

/// Loading skeleton, Arabic error with retry, or the data view. [frame] wraps the loading and error
/// views when the data view brings its own scaffold.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({
    super.key,
    required this.value,
    required this.data,
    required this.onRetry,
    this.frame,
    this.offlineLabel,
    this.onOffline,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback onRetry;
  final Widget Function(Widget child)? frame;

  /// Optional escape from a network error, e.g. «راجع المحتوى المحمّل».
  final String? offlineLabel;
  final VoidCallback? onOffline;

  @override
  Widget build(BuildContext context) {
    final wrap = frame ?? (Widget w) => w;
    return value.when(
      data: data,
      loading: () => wrap(const Align(alignment: Alignment.topCenter, child: PlengoLoadingSkeleton())),
      error: (e, _) {
        final offline = e is ApiException && e.code == 'NETWORK_ERROR';
        return wrap(
          PlengoErrorState(
            icon: offline ? Icons.wifi_off_rounded : Icons.error_outline_rounded,
            hue: offline ? PlengoColors.orange : PlengoColors.red,
            title: e is ApiException ? e.message : ApiException.genericMessage,
            onRetry: onRetry,
            offlineLabel: offline ? offlineLabel : null,
            onOffline: onOffline,
          ),
        );
      },
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
  Widget build(BuildContext context) =>
      PlengoEmptyState(title: text, message: hint, icon: icon, actionLabel: action, onAction: onAction);
}
