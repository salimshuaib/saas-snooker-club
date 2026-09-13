import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_code = """                    onPressed: () {
                      final player = _selectedPayers.isNotEmpty
                          ? _selectedPayers.first
                          : _session.allPlayers.isEmpty
                          ? 'Guest'
                          : _session.allPlayers.first;
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) => PlayerSplitPaymentSheet(
                          playerName: player,
                          totalLiability: _roundedTotal,
                          initialSplits:
                              _playerPaymentSplits[player] ??
                              {_paymentMethod: _roundedTotal},
                          onSplitsSaved: (newSplits) {
                            setState(() {
                              _playerPaymentSplits[player] = newSplits;
                            });
                          },
                        ),
                      );
                    },"""

new_code = """                    onPressed: () {
                      final basePlayer = _selectedPayers.isNotEmpty
                          ? _selectedPayers.first
                          : _session.allPlayers.isEmpty
                          ? 'Guest'
                          : _session.allPlayers.first;
                      final isSingleDefault = !_isMultiPayer && basePlayer.toLowerCase().startsWith('default');
                      final displayPlayer = (isSingleDefault && _PlayerProfileName != null && _PlayerProfileName!.isNotEmpty) 
                          ? _PlayerProfileName! 
                          : basePlayer;

                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (ctx) => PlayerSplitPaymentSheet(
                          playerName: displayPlayer,
                          totalLiability: _roundedTotal,
                          initialSplits:
                              _playerPaymentSplits[basePlayer] ??
                              {_paymentMethod: _roundedTotal},
                          onSplitsSaved: (newSplits) {
                            setState(() {
                              _playerPaymentSplits[basePlayer] = newSplits;
                            });
                          },
                        ),
                      );
                    },"""

text = text.replace(old_code, new_code)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
