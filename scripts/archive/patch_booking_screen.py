import re

with open('lib/features/bookings/presentation/screens/booking_management_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

imports = '''import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/bookings/data/bookings_repository.dart';
import 'package:snooker_club/features/bookings/domain/models/booking_models.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:intl/intl.dart';'''

content = re.sub(r"import 'package:flutter/material\.dart';[\s\S]*?import 'package:intl/intl\.dart';", imports, content)

actions_replacement = '''actions: [
          IconButton(
            icon: const Icon(Icons.link),
            tooltip: 'Copy Booking Link',
            onPressed: () {
              final slug = ref.read(appSettingsProvider).business.slug;
              final clubId = ref.read(clubIdProvider);
              final linkIdentifier = (slug != null && slug.isNotEmpty) ? slug : clubId;
              
              if (linkIdentifier == null) return;
              
              final link = 'https://saas-snooker-club.web.app/?club=\';
              Clipboard.setData(ClipboardData(text: link));
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Copied: \'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),'''

content = content.replace("actions: [", actions_replacement)

with open('lib/features/bookings/presentation/screens/booking_management_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
