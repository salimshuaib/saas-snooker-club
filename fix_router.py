import os

filepath = 'lib/core/routes/app_router.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

bad_route = """                GoRoute(
                  path: RouteNames.quickSales,
                  builder: (context, state) =>
                      const TickerMode(enabled: true, child: QuickSalesScreen()),
                ),"""

good_route = """                GoRoute(
                  path: RouteNames.quickSales,
                  builder: (context, state) =>
                      const TickerMode(enabled: true, child: QuickSalesScreen()),
                  routes: [
                    GoRoute(
                      path: 'new',
                      builder: (context, state) => const TickerMode(
                        enabled: true,
                        child: NewQuickSaleScreen(),
                      ),
                    ),
                    GoRoute(
                      path: 'details',
                      builder: (context, state) {
                        final sale = state.extra as QuickSale;
                        return QuickSaleDetailsScreen(sale: sale);
                      },
                    ),
                  ],
                ),"""

text = text.replace(bad_route, good_route)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
print("SUCCESS")
