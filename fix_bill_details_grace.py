import os

filepath = 'lib/features/games/presentation/screens/bill_details_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_display = """                      if (session.baseGameCharge != null)
                        const _InfoRow(
                          label: 'Grace Period',
                          value: '20 Mins / Frame',
                        ),"""

new_display = """                      if (session.baseGameCharge != null)
                        _InfoRow(
                          label: 'Grace Period',
                          value: session.tableType == TableType.indianPool
                              ? '${ref.read(appSettingsProvider).game.indianPoolGracePeriodMinutes} Mins / Frame'
                              : session.tableType == TableType.americanPool
                                  ? '${ref.read(appSettingsProvider).game.americanPoolGracePeriodMinutes} Mins / Frame'
                                  : '${ref.read(appSettingsProvider).game.frameGracePeriodMinutes} Mins / Frame',
                        ),"""

text = text.replace(old_display, new_display)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
