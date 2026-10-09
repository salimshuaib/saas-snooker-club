import sys

path = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Remove the action
content = content.replace('          const PendingBillsIconBadge(),\n', '')

# Insert the FAB before body
content = content.replace('      body: SafeArea(', '      floatingActionButton: const PendingBillsIconBadge(isFab: true),\n      body: SafeArea(')

# Also Desktop layout has its own Scaffold!
content = content.replace('      body: DesktopDashboardLayout(employeeName: employeeName),', '      floatingActionButton: const PendingBillsIconBadge(isFab: true),\n      body: DesktopDashboardLayout(employeeName: employeeName),')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched dashboard screen')
