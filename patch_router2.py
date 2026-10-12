import re

file_path = 'lib/core/routes/app_router.dart'
try:
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    old_code = """            GoRoute(
              path: 'inventory-details',
              builder: (context, state) {
                final item = state.extra as InventoryItem?;
                if (item == null) {
                  return const Scaffold(
                    body: Center(child: Text('Item not found or session expired.')),
                  );
                }
                return ProductDetailsScreen(item: item);
              },
            ),"""

    new_code = """            GoRoute(
              path: 'inventory-details',
              redirect: (context, state) {
                if (state.extra == null || state.extra is! InventoryItem) {
                  return '/inventory';
                }
                return null;
              },
              builder: (context, state) {
                final item = state.extra as InventoryItem;
                return ProductDetailsScreen(item: item);
              },
            ),"""

    if old_code in content:
        content = content.replace(old_code, new_code)
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print("Patched app_router.dart again")
    else:
        print("Could not find exact block to replace.")
except Exception as e:
    print(f"Error: {e}")
