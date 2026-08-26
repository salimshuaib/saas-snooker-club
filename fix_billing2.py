import re

with open('lib/features/games/presentation/screens/billing_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Only _BillingScreenState has _customLiabilities and _grandTotal
# We need to keep it in class _BillingScreenState extends ConsumerState<BillingScreen>
# but remove it from the other widgets.

bad_lines = r'    final currentSum = _customLiabilities\.values\.fold<double>\(0\.0, \(s, v\) => s \+ v\);\n    final isBalanced = \(_grandTotal - currentSum\)\.abs\(\) < 0\.5;\n'

content = re.sub(r'(class _SectionCard.*?Widget build\(BuildContext context\) \{\n)' + bad_lines, r'\1', content, flags=re.DOTALL)
content = re.sub(r'(class _InfoRow.*?Widget build\(BuildContext context\) \{\n)' + bad_lines, r'\1', content, flags=re.DOTALL)
content = re.sub(r'(class _WinnerTile.*?Widget build\(BuildContext context\) \{\n)' + bad_lines, r'\1', content, flags=re.DOTALL)

with open('lib/features/games/presentation/screens/billing_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
