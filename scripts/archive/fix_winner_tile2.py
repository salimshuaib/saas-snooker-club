import re

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\billing_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''                          _WinnerTile(
                            label: 'Team A (\)',
                            isSelected: _raceSelectedWinnerTeam == 'Team A',
                            onTap: () {
                              setState(() => _raceSelectedWinnerTeam = 'Team A');
                              _initializeLiabilities();
                            },
                          ),
                          _WinnerTile(
                            label: 'Team B (\)',
                            isSelected: _raceSelectedWinnerTeam == 'Team B',
                            onTap: () {
                              setState(() => _raceSelectedWinnerTeam = 'Team B');
                              _initializeLiabilities();
                            },
                          ),'''

replacement = '''                          _WinnerTile(
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
                          ),'''

content = content.replace(target, replacement)

# if the first one didn't work because of the slash
target2 = '''                          _WinnerTile(
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
                          ),'''

content = content.replace(target2, replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
