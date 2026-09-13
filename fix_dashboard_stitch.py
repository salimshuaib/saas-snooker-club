import os
import re

filepath = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# Let's add a darker, sharper container for the stats cards.
stat_card_class = """class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isDesktop ? 4 : 16), // Sharper corners for CRM
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDesktop ? const Color(0xFF15191E) : theme.colorScheme.surface, // Stitch Tier 2 background
          borderRadius: BorderRadius.circular(isDesktop ? 4 : 16),
          border: Border.all(
            color: isDesktop ? const Color(0xFF2C353F) : theme.colorScheme.outlineVariant, 
            width: 1
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: isDesktop ? 20 : 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isDesktop ? const Color(0xFF94A3B8) : theme.colorScheme.onSurfaceVariant,
                      letterSpacing: isDesktop ? 1.1 : null, // Tech feel
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDesktop ? Colors.white : theme.colorScheme.onSurface,
                fontFamily: isDesktop ? 'monospace' : null, // Tabular numbers
              ),
            ),
          ],
        ),
      ),
    );
  }
}"""

# Find the existing _StatCard class and replace it
stat_card_pattern = r'class _StatCard extends StatelessWidget \{.*?\n\}\n'
# We have to match multiple lines.
# Actually, the file has _StatCard somewhere. Let's just use regex with re.DOTALL.
text = re.sub(r'class _StatCard extends StatelessWidget \{.*?\n\}\n', stat_card_class + '\n', text, flags=re.DOTALL)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
print("SUCCESS")
