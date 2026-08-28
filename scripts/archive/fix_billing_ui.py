import re

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\billing_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''            // ── Orders ──'''

replacement = '''            // ── Race Winner Selection ──
            if (_session.gameType == GameType.race) ...[
              Text(
                _session.mode == GameMode.team ? 'Who Won?' : 'Who Will Pay?',
                style: theme.textTheme.titleMedium,
              ),
              const Gap(8),
              _SectionCard(
                children: _session.mode == GameMode.team
                    ? [
                        _WinnerTile(
                          label: 'Team A ()',
                          isSelected: _raceSelectedWinnerTeam == 'Team A',
                          onTap: () {
                            setState(() => _raceSelectedWinnerTeam = 'Team A');
                            _initializeLiabilities();
                          },
                        ),
                        _WinnerTile(
                          label: 'Team B ()',
                          isSelected: _raceSelectedWinnerTeam == 'Team B',
                          onTap: () {
                            setState(() => _raceSelectedWinnerTeam = 'Team B');
                            _initializeLiabilities();
                          },
                        ),
                      ]
                    : _session.allPlayers
                          .map(
                            (p) => _WinnerTile(
                              label: p,
                              isSelected: _raceSelectedPayingPlayer == p,
                              onTap: () {
                                setState(() => _raceSelectedPayingPlayer = p);
                                _initializeLiabilities();
                              },
                            ),
                          )
                          .toList(),
              ),
              const Gap(16),
            ],

            // ── Orders ──'''

content = content.replace(target, replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
