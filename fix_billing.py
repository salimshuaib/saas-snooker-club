import re

with open('lib/features/games/presentation/screens/billing_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Only _BillingScreenState has _customLiabilities and _grandTotal
# We need to remove it from the other widgets

bad_lines = '''    final currentSum = _customLiabilities.values.fold<double>(0.0, (s, v) => s + v);
    final isBalanced = (_grandTotal - currentSum).abs() < 0.5;
'''

# We will split by class, or just specifically replace it in those classes.
content = content.replace(f'class _SectionCard extends StatelessWidget {{\n  const _SectionCard({{required this.children}});\n\n  final List<Widget> children;\n\n  @override\n  Widget build(BuildContext context) {{\n{bad_lines}', 
                          f'class _SectionCard extends StatelessWidget {{\n  const _SectionCard({{required this.children}});\n\n  final List<Widget> children;\n\n  @override\n  Widget build(BuildContext context) {{\n')

content = content.replace(f'class _InfoRow extends StatelessWidget {{\n  final String label;\n  final String value;\n\n  const _InfoRow({{required this.label, required this.value}});\n\n  @override\n  Widget build(BuildContext context) {{\n{bad_lines}', 
                          f'class _InfoRow extends StatelessWidget {{\n  final String label;\n  final String value;\n\n  const _InfoRow({{required this.label, required this.value}});\n\n  @override\n  Widget build(BuildContext context) {{\n')

content = content.replace(f'class _WinnerTile extends StatelessWidget {{\n  final String title;\n  final bool isSelected;\n  final VoidCallback onTap;\n\n  const _WinnerTile({{\n    required this.title,\n    required this.isSelected,\n    required this.onTap,\n  }});\n\n  @override\n  Widget build(BuildContext context) {{\n{bad_lines}', 
                          f'class _WinnerTile extends StatelessWidget {{\n  final String title;\n  final bool isSelected;\n  final VoidCallback onTap;\n\n  const _WinnerTile({{\n    required this.title,\n    required this.isSelected,\n    required this.onTap,\n  }});\n\n  @override\n  Widget build(BuildContext context) {{\n')

with open('lib/features/games/presentation/screens/billing_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
