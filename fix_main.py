import re

with open('lib/features/dashboard/presentation/screens/main_screen.dart', 'r', encoding='utf-8') as f:
    text = f.read()

# Fix the container color
text = re.sub(r"color: AppColors\.previewPrimaryDark,", r"color: theme.colorScheme.surface,", text)
text = re.sub(r"border: Border\.all\(color: AppColors\.previewLine\),", r"border: Border.all(color: theme.colorScheme.outlineVariant),", text)

# Fix the active colors for bottom navigation items
text = re.sub(r"activeColor: AppColors\.previewSecondary,", r"activeColor: theme.colorScheme.primary,", text)
text = re.sub(r"activeColor: AppColors\.previewError,", r"activeColor: theme.colorScheme.primary,", text)
text = re.sub(r"inactiveColor: AppColors\.previewError\.withOpacity\(0\.6\),", r"", text)

# Fix the label color
text = re.sub(r"final labelColor = isActive \? AppColors\.previewLightBackground : effectiveInactiveColor;", r"final labelColor = isActive ? activeColor : effectiveInactiveColor;", text)

with open('lib/features/dashboard/presentation/screens/main_screen.dart', 'w', encoding='utf-8') as f:
    f.write(text)
