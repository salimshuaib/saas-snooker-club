import os
import re

# 1. Update dashboard_screen.dart
filepath = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

import_stmt = "import 'package:snooker_club/features/games/presentation/widgets/pending_bills_icon_badge.dart';"
if import_stmt not in content:
    content = content.replace("import 'package:snooker_club/core/theme/app_colors.dart';",
                              "import 'package:snooker_club/core/theme/app_colors.dart';\n" + import_stmt)

# Add before Center(child: Padding(...))
if 'PendingBillsIconBadge()' not in content:
    old_actions = '''actions: [
          Center('''
    new_actions = '''actions: [
          const PendingBillsIconBadge(),
          Center('''
    content = content.replace(old_actions, new_actions)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)


# 2. Update transaction_history_screen.dart
filepath = 'lib/features/history/presentation/screens/transaction_history_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

import_stmt = "import 'package:snooker_club/features/games/presentation/widgets/pending_bills_icon_badge.dart';"
if import_stmt not in content:
    content = content.replace("import 'package:snooker_club/features/history/presentation/widgets/audit_log_sheet.dart';",
                              "import 'package:snooker_club/features/history/presentation/widgets/audit_log_sheet.dart';\n" + import_stmt)

if 'PendingBillsIconBadge()' not in content:
    old_actions = '''          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () => _onDeleteSelected(gamesListAsync.asData?.value ?? []),
            )
          else
            IconButton('''
    new_actions = '''          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete, color: AppColors.error),
              onPressed: () => _onDeleteSelected(gamesListAsync.asData?.value ?? []),
            )
          else ...[
            const PendingBillsIconBadge(),
            IconButton('''
            
    # And we need to close the list spread
    #             );
    #           },
    #         ),
    #     ],
    
    # Actually just replace the 'else' block
    old_else = '''          else
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AuditLogSheet(),
                );
              },
            ),'''
            
    new_else = '''          else ...[
            const PendingBillsIconBadge(),
            IconButton(
              icon: const Icon(Icons.history),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AuditLogSheet(),
                );
              },
            ),
          ],'''
    content = content.replace(old_else, new_else)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print('Phase 4 complete')
