import os

filepath = 'lib/features/dashboard/presentation/screens/desktop_dashboard_layout.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# Add imports
imports = """
import 'package:snooker_club/features/dashboard/presentation/screens/financial_review_screen.dart';
import 'package:snooker_club/features/credit/presentation/screens/credit_screen.dart';
import 'package:snooker_club/features/quick_sales/presentation/screens/quick_sales_screen.dart';
import 'package:snooker_club/features/settings/presentation/screens/settings_screen.dart';
import 'package:snooker_club/features/bookings/presentation/screens/booking_management_screen.dart';
"""
text = text.replace("import 'package:snooker_club/core/routes/route_names.dart';", "import 'package:snooker_club/core/routes/route_names.dart';" + imports)

# Replace navigation
text = text.replace(
    "context.push(RouteNames.financialReview)", 
    "Navigator.push(context, MaterialPageRoute(builder: (c) => const FinancialReviewScreen()))"
)
text = text.replace(
    "context.push(RouteNames.credit)", 
    "Navigator.push(context, MaterialPageRoute(builder: (c) => const CreditScreen()))"
)
text = text.replace(
    "context.push(RouteNames.quickSales)", 
    "Navigator.push(context, MaterialPageRoute(builder: (c) => const QuickSalesScreen()))"
)
text = text.replace(
    "context.push(RouteNames.bookings)", 
    "Navigator.push(context, MaterialPageRoute(builder: (c) => const BookingManagementScreen()))"
)
text = text.replace(
    "context.push(RouteNames.settings)", 
    "Navigator.push(context, MaterialPageRoute(builder: (c) => const SettingsScreen()))"
)

# Make entire Financial Breakdown card clickable
old_breakdown = """    return AnimatedHoverCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Financial breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                ),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const FinancialReviewScreen())),
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Icon(Icons.chevron_right, size: 18, color: Color(0xFF8B8EA3)),
                  ),
                ),
              ],
            ),"""

new_breakdown = """    return AnimatedHoverCard(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const FinancialReviewScreen())),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Financial breakdown',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white),
                ),
                const Icon(Icons.chevron_right, size: 18, color: Color(0xFF8B8EA3)),
              ],
            ),"""

text = text.replace(old_breakdown, new_breakdown)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)

print("Navigation fixed")
