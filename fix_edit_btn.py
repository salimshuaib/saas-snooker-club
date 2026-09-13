import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_code = """                          Text(
                            _renamedPlayers[player] ?? player,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Gap(8),"""

new_code = """                          Text(
                            _renamedPlayers[player] ?? player,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit, size: 16, color: Colors.grey),
                            onPressed: () => _showCreditNameDialog(player, autoConfirm: false, setMethod: false),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            constraints: const BoxConstraints(),
                            tooltip: 'Rename Player',
                          ),
                          const Gap(4),"""

text = text.replace(old_code, new_code)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
