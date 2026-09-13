import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

/// Generic draggable bottom sheet.
class AppBottomSheet extends StatelessWidget {
  final String? title;
  final Widget child;
  final List<Widget>? actions;

  const AppBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.actions,
  });

  /// Show the bottom sheet.
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    required Widget child,
    List<Widget>? actions,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      useRootNavigator: true,
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: true,
      builder: (context) =>
          AppBottomSheet(title: title, actions: actions, child: child),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
        left: 20,
        right: 20,
        top: 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title!, style: theme.textTheme.titleLarge),
            const Gap(16),
          ],
          child,
          if (actions != null) ...[
            const Gap(16),
            Row(mainAxisAlignment: MainAxisAlignment.end, children: actions!),
          ],
          const Gap(20),
        ],
      ),
    );
  }
}
