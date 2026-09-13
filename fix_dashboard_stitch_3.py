import os
import re

filepath = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

module_card = """class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isDesktop ? 4 : 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDesktop ? const Color(0xFF1A2026) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(isDesktop ? 4 : 16),
          border: Border.all(color: isDesktop ? const Color(0xFF2C353F) : theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(isDesktop ? 4 : 10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: isDesktop ? Colors.grey : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleSmall?.copyWith(color: isDesktop ? Colors.white : null)),
                Text(
                  description,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDesktop ? const Color(0xFF94A3B8) : theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}"""

text = re.sub(r'class _ModuleCard extends StatelessWidget \{.*?\n\}\n\}', module_card + '\n', text, flags=re.DOTALL)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
print("SUCCESS")
