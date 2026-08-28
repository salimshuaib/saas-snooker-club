import os

def fix_errors():
    # 1. Dashboard clock
    path1 = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
    if os.path.exists(path1):
        with open(path1, 'r', encoding='utf-8') as f:
            content1 = f.read()
            
        old_col = """                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        timeStr,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        dateStr,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),"""
        content1 = content1.replace(old_col, '                  const _RealTimeClockWidget(),')
        with open(path1, 'w', encoding='utf-8') as f:
            f.write(content1)

    # 2. Quick sale screen _isLoading -> _isProcessing
    path2 = 'lib/features/quick_sales/presentation/screens/new_quick_sale_screen.dart'
    if os.path.exists(path2):
        with open(path2, 'r', encoding='utf-8') as f:
            content2 = f.read()
            
        content2 = content2.replace('if (_isLoading) return;', 'if (_isProcessing) return;')
        with open(path2, 'w', encoding='utf-8') as f:
            f.write(content2)

if __name__ == '__main__':
    fix_errors()
