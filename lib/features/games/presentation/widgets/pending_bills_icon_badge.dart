import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';

class PendingBillsIconBadge extends ConsumerWidget {
  final bool isFab;
  const PendingBillsIconBadge({Key? key, this.isFab = false}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(pendingBillsCountProvider);
    final bills = ref.watch(pendingBillsProvider).asData?.value ?? [];
    final hasOverdue = bills.any((b) => DateTime.now().difference(b.markedPendingAt ?? DateTime.now()).inDays >= 7);
    final theme = Theme.of(context);

    if (isFab) {
      
      return Stack(
        clipBehavior: Clip.none,
        children: [
          FloatingActionButton(
            heroTag: null,
            backgroundColor: Colors.yellow,
            onPressed: () => context.push(RouteNames.pendingBills),
            tooltip: 'Pending Bills',
            child: const Icon(Icons.shopping_basket, color: Colors.black),
          ),
          if (count > 0) Positioned(
            right: -4,
            top: -4,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: hasOverdue ? AppColors.error : AppColors.error,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              constraints: const BoxConstraints(
                minWidth: 24,
                minHeight: 24,
              ),
              child: Text(
                count > 99 ? '99+' : count.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  height: 1,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      );
    }

    // Regular AppBar icon
    if (count == 0) {
      return IconButton(
        icon: const Icon(Icons.shopping_basket, color: Colors.yellow),
        tooltip: 'Pending Bills',
        onPressed: () => context.push(RouteNames.pendingBills),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_basket, color: Colors.yellow),
          tooltip: 'Pending Bills',
          onPressed: () => context.push(RouteNames.pendingBills),
        ),
        Positioned(
          right: 4,
          top: 4,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: hasOverdue ? AppColors.error : AppColors.error,
              shape: BoxShape.circle,
            ),
            constraints: const BoxConstraints(
              minWidth: 18,
              minHeight: 18,
            ),
            child: Text(
              count > 99 ? '99+' : count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                height: 1,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }
}
