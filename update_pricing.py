import os

filepath = 'lib/features/games/domain/config/pricing_config.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_logic = """          final int currentOvertimeSeconds =
              currentFrameSeconds - (gameConfig.frameGracePeriodMinutes * 60);"""

new_logic = """          int gracePeriodMinutes = gameConfig.frameGracePeriodMinutes;
          if (tableType == TableType.indianPool) {
             gracePeriodMinutes = gameConfig.indianPoolGracePeriodMinutes;
          } else if (tableType == TableType.americanPool) {
             gracePeriodMinutes = gameConfig.americanPoolGracePeriodMinutes;
          }
          final int currentOvertimeSeconds =
              currentFrameSeconds - (gracePeriodMinutes * 60);"""

text = text.replace(old_logic, new_logic)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
