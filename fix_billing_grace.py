import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_display = """                    _InfoRow(
                      label: 'Grace Period',
                      value:
                          '${TablePricingConfig.frameGracePeriodMinutes} Mins / Frame',
                    ),"""

new_display = """                    _InfoRow(
                      label: 'Grace Period',
                      value: _session.tableType == TableType.indianPool
                          ? '${ref.read(appSettingsProvider).game.indianPoolGracePeriodMinutes} Mins / Frame'
                          : _session.tableType == TableType.americanPool
                              ? '${ref.read(appSettingsProvider).game.americanPoolGracePeriodMinutes} Mins / Frame'
                              : '${ref.read(appSettingsProvider).game.frameGracePeriodMinutes} Mins / Frame',
                    ),"""

text = text.replace(old_display, new_display)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
