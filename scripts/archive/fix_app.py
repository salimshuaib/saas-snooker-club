import sys

file_path = 'lib/app.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''        if (AppConfig.isPreview) {
          return Banner(
            message: 'PREVIEW',
            location: BannerLocation.topEnd,
            color: Colors.deepOrange,
            child: child ?? const SizedBox.shrink(),
          );
        }
        return child ?? const SizedBox.shrink();
      },'''

repl = '''        Widget builtChild = child ?? const SizedBox.shrink();
        if (AppConfig.isPreview) {
          builtChild = Banner(
            message: 'PREVIEW',
            location: BannerLocation.topEnd,
            color: Colors.deepOrange,
            child: builtChild,
          );
        }
        return _GlobalProviderKeeper(child: builtChild);
      },'''

if target in content:
    content = content.replace(target, repl)
    
    # Now we need to append the _GlobalProviderKeeper class
    append_class = '''

import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/quick_sales/providers/quick_sales_providers.dart';
import 'package:snooker_club/features/inventory/providers/inventory_providers.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/core/providers/update_provider.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/analytics/providers/analytics_providers.dart';
import 'package:snooker_club/features/dashboard/providers/financial_providers.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';

class _GlobalProviderKeeper extends ConsumerWidget {
  final Widget child;
  const _GlobalProviderKeeper({required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch these critical providers ABOVE the Navigator.
    // Since this widget is outside the Navigator, it is never subject to TickerMode pausing.
    // This entirely prevents Riverpod TickerMode queueing bugs when routes transition!
    ref.watch(tablesProvider);
    ref.watch(resolvedTablesProvider);
    ref.watch(runningTablesCountProvider);
    ref.watch(availableTablesCountProvider);
    ref.watch(appSettingsProvider);
    ref.watch(todaysGamesRevenueStreamProvider);
    ref.watch(pendingCreditsProvider);
    ref.watch(todaysQuickSalesCountProvider);
    ref.watch(inventoryItemsProvider);
    ref.watch(currentStaffProvider);
    ref.watch(updateStateProvider);
    ref.watch(allCustomersProvider);
    ref.watch(completeAnalyticsProvider);
    ref.watch(financialSummaryProvider);

    return child;
  }
}
'''
    # We must insert the imports at the top if they are missing
    content += append_class
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Fixed app.dart")
else:
    print("Target not found in app.dart")
