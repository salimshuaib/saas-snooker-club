import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';

class TableCard extends ConsumerWidget {
  final TableModel table;
  final DateTime selectedDate;
  final bool isToday;

  const TableCard({
    super.key,
    required this.table,
    required this.selectedDate,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeGameAsync = ref.watch(activeGameProvider(table.id));

    return GestureDetector(
      onTap: () {
        context.push(
          '/games/table',
          extra: {
            'table': table,
            'selectedDate': selectedDate,
            'isToday': isToday,
          },
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _statusColor(table.status).withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: _statusColor(table.status).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatusBadge(status: table.status),
                Icon(
                  _tableIcon(table.type),
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const Spacer(),

            // Table Name
            Text(
              table.name,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Gap(2),
            Text(
              table.type.displayName,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Gap(8),

            // Timer + Bill (only when running/paused)
            activeGameAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (game) {
                if (game == null) return const SizedBox.shrink();
                return _ActiveGameInfo(game: game);
              },
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(TableStatus status) {
    switch (status) {
      case TableStatus.available:
        return AppColors.available;
      case TableStatus.running:
        return AppColors.running;
      case TableStatus.paused:
        return AppColors.paused;
      case TableStatus.billing:
        return AppColors.billing;
    }
  }

  IconData _tableIcon(TableType type) {
    switch (type) {
      case TableType.snooker:
        return Icons.sports_esports;
      case TableType.indianPool:
        return Icons.circle_outlined;
      case TableType.americanPool:
        return Icons.sports_golf;
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final TableStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == TableStatus.running)
            _PulseDot(color: color)
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          const Gap(4),
          Text(
            status.displayName,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Color _statusColor() {
    switch (status) {
      case TableStatus.available:
        return AppColors.available;
      case TableStatus.running:
        return AppColors.running;
      case TableStatus.paused:
        return AppColors.paused;
      case TableStatus.billing:
        return AppColors.billing;
    }
  }
}

class _PulseDot extends StatefulWidget {
  final Color color;

  const _PulseDot({required this.color});

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.4, end: 1.0).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) => Container(
        width: 6,
        height: 6,
        decoration: BoxDecoration(
          color: widget.color.withValues(alpha: _animation.value),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _ActiveGameInfo extends ConsumerStatefulWidget {
  final GameSession game;

  const _ActiveGameInfo({required this.game});

  @override
  ConsumerState<_ActiveGameInfo> createState() => _ActiveGameInfoState();
}

class _ActiveGameInfoState extends ConsumerState<_ActiveGameInfo> {
  @override
  Widget build(BuildContext context) {
    // Watch the per-second tick for local timer updates
    ref.watch(gameTimerProvider(widget.game.id));
    final seconds = widget.game.activeSeconds;

    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    final timeStr = seconds >= 3600 ? '$h:$m:$s' : '$m:$s';

    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.timer,
            size: 12, color: theme.colorScheme.onSurfaceVariant),
        const Gap(4),
        Text(
          timeStr,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.running,
          ),
        ),
      ],
    );
  }
}
