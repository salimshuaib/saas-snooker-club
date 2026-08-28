path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\dashboard\presentation\screens\main_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Add listenManuals to initState
init_state_repl = '''  @override
  void initState() {
    super.initState();
    ref.listenManual<String?>(clubIdProvider, (previous, next) {
      if (next != null) {
        _triggerInitialization(next);
      }
    }, fireImmediately: true);

    // Keep critical providers active at the root level to prevent 
    // Riverpod TickerMode crashes when switching GoRouter tabs or dialogs.
    // Using listenManual bypasses TickerMode pausing completely.
    ref.listenManual(tablesProvider, (_, __) {});
    ref.listenManual(resolvedTablesProvider, (_, __) {});
    ref.listenManual(runningTablesCountProvider, (_, __) {});
    ref.listenManual(availableTablesCountProvider, (_, __) {});
    ref.listenManual(appSettingsProvider, (_, __) {});
    ref.listenManual(todaysGamesRevenueStreamProvider, (_, __) {});
    ref.listenManual(pendingCreditsProvider, (_, __) {});
    ref.listenManual(todaysQuickSalesCountProvider, (_, __) {});
    ref.listenManual(inventoryItemsProvider, (_, __) {});
    ref.listenManual(currentStaffProvider, (_, __) {});
    ref.listenManual(updateStateProvider, (_, __) {});
  }'''

content = content.replace('''  @override
  void initState() {
    super.initState();
    ref.listenManual<String?>(clubIdProvider, (previous, next) {
      if (next != null) {
        _triggerInitialization(next);
      }
    }, fireImmediately: true);
  }''', init_state_repl)

# Remove the ref.watch calls from build
remove_watch = '''// Keep critical providers active at the root level to prevent 
    // Riverpod TickerMode crashes when switching GoRouter tabs.
    // We must watch the derived stream providers too so they don't pause!
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
    ref.watch(updateStateProvider);'''

content = content.replace(remove_watch, '')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
