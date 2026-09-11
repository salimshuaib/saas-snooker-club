import sys

with open('lib/features/dashboard/presentation/screens/main_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Replace build method
old_build = '''  @override
  Widget build(BuildContext context) {
    if (_isSwitchingClub) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final clubId = ref.watch(clubIdProvider);
    if (clubId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      body: widget.navigationShell,
      floatingActionButton: Container(
        height: 64,
        width: 64,
        margin: const EdgeInsets.only(top: 30),
        child: FloatingActionButton(
          onPressed: _showStartGameFlow,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
          child: const Icon(Icons.add, size: 36),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: theme.colorScheme.surface,
        elevation: 8,
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(
              icon: Icons.dashboard_outlined,
              activeIcon: Icons.dashboard,
              label: 'Dashboard',
              isActive: currentIndex == 0,
              onTap: () => _onItemTapped(0),
              theme: theme,
            ),
            const SizedBox(width: 48), // Space for FAB
            _buildNavItem(
              icon: Icons.receipt_long_outlined,
              activeIcon: Icons.receipt_long,
              label: 'History',
              isActive: currentIndex == 1,
              onTap: () => _onItemTapped(1),
              theme: theme,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final color = isActive ? AppColors.primary : theme.colorScheme.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 0.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 28),
            const SizedBox(height: 2),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }'''

new_build = '''  @override
  Widget build(BuildContext context) {
    if (_isSwitchingClub) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final clubId = ref.watch(clubIdProvider);
    if (clubId == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final theme = Theme.of(context);
    final currentIndex = widget.navigationShell.currentIndex;

    return Scaffold(
      extendBody: true, // Needed for floating bottom nav
      body: widget.navigationShell,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 16.0, right: 16.0, bottom: 16.0),
          decoration: BoxDecoration(
            color: AppColors.previewPrimaryDark,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: AppColors.previewLine),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  icon: Icons.table_restaurant_outlined,
                  activeIcon: Icons.table_restaurant,
                  label: 'Live',
                  isActive: currentIndex == 0,
                  activeColor: AppColors.previewSecondary,
                  onTap: () => _onItemTapped(0),
                  theme: theme,
                ),
                _buildNavItem(
                  icon: Icons.flash_on_outlined,
                  activeIcon: Icons.flash_on,
                  label: 'Quick Sale',
                  isActive: currentIndex == 1,
                  activeColor: AppColors.previewError,
                  inactiveColor: AppColors.previewError.withOpacity(0.6),
                  onTap: () => _onItemTapped(1),
                  theme: theme,
                ),
                _buildNavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'History',
                  isActive: currentIndex == 2,
                  activeColor: AppColors.previewSecondary,
                  onTap: () => _onItemTapped(2),
                  theme: theme,
                ),
                _buildNavItem(
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                  label: 'Overview',
                  isActive: currentIndex == 3,
                  activeColor: AppColors.previewSecondary,
                  onTap: () => _onItemTapped(3),
                  theme: theme,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required Color activeColor,
    Color? inactiveColor,
    required VoidCallback onTap,
    required ThemeData theme,
  }) {
    final effectiveInactiveColor = inactiveColor ?? theme.colorScheme.onSurfaceVariant;
    final color = isActive ? activeColor : effectiveInactiveColor;
    final labelColor = isActive ? AppColors.previewLightBackground : effectiveInactiveColor;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: labelColor,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }'''
text = text.replace(old_build, new_build)

with open('lib/features/dashboard/presentation/screens/main_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
print("Updated successfully")
