import os

def patch_double_tap():
    # 1. Billing Screen
    path1 = 'lib/features/games/presentation/screens/billing_screen.dart'
    if os.path.exists(path1):
        with open(path1, 'r', encoding='utf-8') as f:
            content1 = f.read()
        if 'if (_isProcessing) return;' not in content1:
            content1 = content1.replace('Future<void> _confirmPayment() async {', 'Future<void> _confirmPayment() async {\n    if (_isProcessing) return;')
            with open(path1, 'w', encoding='utf-8') as f:
                f.write(content1)

    # 2. Player Profile Screen
    path2 = 'lib/features/credit/presentation/screens/player_profile_screen.dart'
    if os.path.exists(path2):
        with open(path2, 'r', encoding='utf-8') as f:
            content2 = f.read()
        if 'if (_isLoading) return;' not in content2:
            content2 = content2.replace('Future<void> _submitPayment() async {', 'Future<void> _submitPayment() async {\n    if (_isLoading) return;')
            with open(path2, 'w', encoding='utf-8') as f:
                f.write(content2)

    # 3. Quick Sale Screen
    path3 = 'lib/features/quick_sales/presentation/screens/new_quick_sale_screen.dart'
    if os.path.exists(path3):
        with open(path3, 'r', encoding='utf-8') as f:
            content3 = f.read()
        if 'if (_isLoading) return;' not in content3:
            content3 = content3.replace('Future<void> _processSale() async {', 'Future<void> _processSale() async {\n    if (_isLoading) return;')
            with open(path3, 'w', encoding='utf-8') as f:
                f.write(content3)

if __name__ == '__main__':
    patch_double_tap()
