import 'package:flutter/material.dart';
import 'package:snooker_club/core/widgets/crm_sidebar.dart';

import 'package:snooker_club/core/widgets/gaming_background.dart';

class ResponsiveScaffoldWrapper extends StatelessWidget {
  final Widget child;

  const ResponsiveScaffoldWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    if (!isDesktop) {
      return child;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: GamingBackground(
        child: Row(
          children: [
            const CRMSidebar(),
            Expanded(
              child: ClipRect(
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
