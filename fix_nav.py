import os

filepath = 'lib/features/dashboard/presentation/screens/main_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

start_token = "              children: ["
end_token = "              ],\n            ),"
start_idx = text.find(start_token)
end_idx = text.find(end_token, start_idx)

children_text = text[start_idx:end_idx]

new_children = """              children: [
                _buildNavItem(
                  icon: Icons.table_restaurant_outlined,
                  activeIcon: Icons.table_restaurant,
                  label: 'Live',
                  isActive: currentIndex == 0,
                  activeColor: theme.colorScheme.primary,
                  onTap: () => _onItemTapped(0),
                  theme: theme,
                ),
                _buildNavItem(
                  icon: Icons.menu_book_outlined,
                  activeIcon: Icons.menu_book,
                  label: 'Khata',
                  isActive: currentIndex == 1,
                  activeColor: theme.colorScheme.primary,
                  onTap: () => _onItemTapped(1),
                  theme: theme,
                ),
                _buildNavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long,
                  label: 'History',
                  isActive: currentIndex == 2,
                  activeColor: theme.colorScheme.primary,
                  onTap: () => _onItemTapped(2),
                  theme: theme,
                ),
                _buildNavItem(
                  icon: Icons.bar_chart_outlined,
                  activeIcon: Icons.bar_chart,
                  label: 'Overview',
                  isActive: currentIndex == 3,
                  activeColor: theme.colorScheme.primary,
                  onTap: () => _onItemTapped(3),
                  theme: theme,
                ),
                _buildNavItem(
                  icon: Icons.flash_on_outlined,
                  activeIcon: Icons.flash_on,
                  label: 'Quick Sale',
                  isActive: currentIndex == 4,
                  activeColor: theme.colorScheme.primary,
                  onTap: () => _onItemTapped(4),
                  theme: theme,
                ),"""

text = text.replace(children_text, new_children)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
