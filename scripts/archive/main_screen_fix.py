path = r'c:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\dashboard\presentation\screens\main_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('''  @override
  void initState() {
    super.initState();
    // Initialize collections
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gamesRepositoryProvider).seedTablesIfEmpty();
      ref.read(settingsRepositoryProvider).migrateTablesPricing();
    });
  }''', '''  bool _hasInitialized = false;

  void _triggerInitialization(String clubId) {
    if (_hasInitialized) return;
    _hasInitialized = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gamesRepositoryProvider).seedTablesIfEmpty();
      ref.read(settingsRepositoryProvider).migrateTablesPricing();
    });
  }

  @override
  void initState() {
    super.initState();
  }''')

content = content.replace('''  @override
  Widget build(BuildContext context) {''', '''  @override
  Widget build(BuildContext context) {
    ref.listen(clubIdProvider, (previous, next) {
      if (next != null) {
        _triggerInitialization(next);
      }
    }, fireImmediately: true);''')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
