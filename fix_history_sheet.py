import os
import re

filepath = 'lib/features/games/presentation/widgets/table_history_sheet.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("final num price = game.grandTotal ?? 0;", "final num price = game.roundedAmount ?? game.finalAmount ?? game.grandTotal ?? 0;")

old_start_time = """              Text(
                dtFmt.format(game.startTime),
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),"""
new_start_time = """              Text(
                dtFmt.format(game.startTime),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),"""
text = text.replace(old_start_time, new_start_time)

old_end_time = """                Text(
                  dtFmt.format(game.endTime!),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),"""
new_end_time = """                Text(
                  dtFmt.format(game.endTime!),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),"""
text = text.replace(old_end_time, new_end_time)

old_players = """                Text(
                  players.join(' vs '),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),"""
new_players = """                Text(
                  players.join(' vs '),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),"""
text = text.replace(old_players, new_players)

# Replace the specific details text using regex to avoid mojibake parsing errors
pattern = r"Text\(\s*'\$duration\s*[^\$]+\$price',\s*style: theme\.textTheme\.labelSmall\?\.copyWith\(\s*color: theme\.colorScheme\.onSurfaceVariant,\s*\),\s*\)"
replacement = r"""Text(
                  '$duration  \u2022  \u20B9${price.toStringAsFixed(0)}',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )"""
text = re.sub(pattern, replacement, text)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
