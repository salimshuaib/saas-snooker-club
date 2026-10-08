import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/bookings/data/bookings_repository.dart';
import 'package:snooker_club/features/bookings/domain/models/booking_models.dart';
import 'package:snooker_club/features/bookings/presentation/widgets/booking_settings_sheet.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';

class BookingManagementScreen extends ConsumerStatefulWidget {
  const BookingManagementScreen({super.key});

  @override
  ConsumerState<BookingManagementScreen> createState() =>
      _BookingManagementScreenState();
}

class _BookingManagementScreenState
    extends ConsumerState<BookingManagementScreen> {
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  void _openBookingSettings() {
    final settings = ref.read(appSettingsProvider);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => BookingSettingsSheet(
        initialSettings: settings.booking,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookingsAsync = ref.watch(dateBookingsStreamProvider(_selectedDate));
    final bookingSettings = ref.watch(appSettingsProvider.select((s) => s.booking));

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bookings'),
          actions: [
            IconButton(
              icon: const Icon(Icons.tune),
              tooltip: 'Time Slots & Booking Controls',
              onPressed: _openBookingSettings,
            ),
            IconButton(
              icon: const Icon(Icons.link),
              tooltip: 'Copy Booking Link',
              onPressed: () {
                final slug = ref.read(clubProfileProvider).value?.slug;
                final clubId = ref.read(clubIdProvider);
                final linkIdentifier = (slug != null && slug.isNotEmpty)
                    ? slug
                    : clubId;

                if (linkIdentifier == null) return;

                final link =
                    'https://saas-snooker-bookings.web.app/?club=${linkIdentifier}';
                Clipboard.setData(ClipboardData(text: link));

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Copied: $link'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.calendar_today),
              tooltip: 'Select Date',
              onPressed: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  setState(
                    () => _selectedDate = DateTime(
                      date.year,
                      date.month,
                      date.day,
                    ),
                  );
                }
              },
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Upcoming'),
              Tab(text: 'Completed'),
              Tab(text: 'Cancelled'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: bookingsAsync.when(
                data: (allBookings) {
                  final upcoming = allBookings
                      .where(
                        (b) =>
                            b.status == BookingStatus.unconfirmed ||
                            b.status == BookingStatus.confirmed,
                      )
                      .toList();
                  final completed = allBookings
                      .where((b) => b.status == BookingStatus.completed)
                      .toList();
                  final cancelled = allBookings
                      .where((b) => b.status == BookingStatus.cancelled)
                      .toList();

                  return TabBarView(
                    children: [
                      _buildList(upcoming, 'No upcoming bookings.'),
                      _buildList(completed, 'No completed bookings.'),
                      _buildList(cancelled, 'No cancelled bookings.'),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, st) => Center(child: Text('Error: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<BookingModel> bookings, String emptyMessage) {
    if (bookings.isEmpty) {
      return Center(
        child: Text(emptyMessage, style: const TextStyle(color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _BookingCard(booking: booking);
      },
    );
  }
}

class _BookingCard extends ConsumerWidget {
  final BookingModel booking;

  const _BookingCard({required this.booking});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    Color getStatusColor() {
      switch (booking.status) {
        case BookingStatus.unconfirmed:
          return AppColors.error;
        case BookingStatus.confirmed:
          return AppColors.running;
        case BookingStatus.cancelled:
          return AppColors.completed;
        case BookingStatus.completed:
          return AppColors.success;
      }
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  booking.customerName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: getStatusColor().withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: getStatusColor()),
                  ),
                  child: Text(
                    booking.status.displayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: getStatusColor(),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 16),
                const SizedBox(width: 8),
                Text(booking.customerPhone),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.table_restaurant, size: 16),
                const SizedBox(width: 8),
                Text(
                  booking.tableName,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.schedule, size: 16),
                const SizedBox(width: 8),
                Text(
                  '${DateFormat('h:mm a').format(booking.startTime)} - ${DateFormat('h:mm a').format(booking.endTime)}',
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            if (booking.notes != null && booking.notes!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Note: ${booking.notes}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
            if (booking.status == BookingStatus.unconfirmed) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      ref
                          .read(bookingsRepositoryProvider)
                          .updateBookingStatus(
                            booking.id,
                            BookingStatus.cancelled,
                          );
                    },
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: () {
                      ref
                          .read(bookingsRepositoryProvider)
                          .updateBookingStatus(
                            booking.id,
                            BookingStatus.confirmed,
                          );
                    },
                    child: const Text('Confirm Booking'),
                  ),
                ],
              ),
            ] else if (booking.status == BookingStatus.confirmed) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      ref
                          .read(bookingsRepositoryProvider)
                          .updateBookingStatus(
                            booking.id,
                            BookingStatus.cancelled,
                          );
                    },
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.tonal(
                    onPressed: () {
                      ref
                          .read(bookingsRepositoryProvider)
                          .updateBookingStatus(
                            booking.id,
                            BookingStatus.completed,
                          );
                    },
                    child: const Text('Mark Completed'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
