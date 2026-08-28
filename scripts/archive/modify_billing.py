import re

with open('lib/features/games/presentation/screens/billing_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Add _customLiabilities and _isSplitBill (for Team Race)
state_vars_old = '''  late Map<String, PaymentMethod> _playerPaymentMethods;
  bool _isProcessing = false;'''
state_vars_new = '''  late Map<String, PaymentMethod> _playerPaymentMethods;
  late Map<String, double> _customLiabilities;
  bool _isProcessing = false;'''
content = content.replace(state_vars_old, state_vars_new)

# Replace the _calculatedLiabilities getter with a one-time initialization
calc_liabilities_pattern = re.compile(r'  Map<String, double> get _calculatedLiabilities \{.*?\n  \}\n', re.DOTALL)

init_method_old = '''  @override
  void initState() {
    super.initState();
    _session = widget.session.copyWith(endTime: DateTime.now());
    if (_session.matchType == MatchType.friendly) {
      _winnerId = null;
    }
    _playerPaymentMethods = {
      for (final p in _session.allPlayers) p: PaymentMethod.cash,
    };
  }'''

init_method_new = '''  @override
  void initState() {
    super.initState();
    _session = widget.session.copyWith(endTime: DateTime.now());
    if (_session.matchType == MatchType.friendly) {
      _winnerId = null;
    }
    _playerPaymentMethods = {
      for (final p in _session.allPlayers) p: PaymentMethod.cash,
    };
    // Initialization of _customLiabilities will happen in didChangeDependencies
    // to safely access ref.read for pricing breakdown
  }

  bool _liabilitiesInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_liabilitiesInitialized) {
      _initializeLiabilities();
      _liabilitiesInitialized = true;
    }
  }

  void _initializeLiabilities() {
    final Map<String, double> liabilities = {
      for (final p in _session.allPlayers) p: 0.0,
    };

    final totalToSplit = _grandTotal; // _grandTotal uses _gameCharge + _ordersTotal

    if (_session.gameType == GameType.rummy) {
      // Rummy: Split evenly across all players
      final split = totalToSplit / (_session.allPlayers.isEmpty ? 1 : _session.allPlayers.length);
      for (final p in _session.allPlayers) {
        liabilities[p] = split;
      }
    } else if (_session.gameType == GameType.race) {
      if (_session.mode == GameMode.solo) {
        // Race Solo: Loser (lowest points) pays 100%
        String? loser;
        int lowestPoints = 999999;
        for (final p in _session.allPlayers) {
          final pts = _session.playerPoints?[p] ?? 0;
          if (pts < lowestPoints) {
            lowestPoints = pts;
            loser = p;
          }
        }
        if (loser != null) liabilities[loser] = totalToSplit;
      } else {
        // Race Team: Losing team (lowest points) splits bill
        final teamAPts = _session.playerPoints?['Team A'] ?? 0;
        final teamBPts = _session.playerPoints?['Team B'] ?? 0;
        final losingTeam = teamAPts <= teamBPts ? _session.teamA : _session.teamB;
        if (losingTeam.isNotEmpty) {
          final split = totalToSplit / losingTeam.length;
          for (final p in losingTeam) {
            liabilities[p] = split;
          }
        }
      }
    } else {
      // Standard / TP Logic
      if (_session.rounds.isNotEmpty) {
        for (final r in _session.rounds) {
          final roundTotal = r.roundCost + (r.overtimeCharge ?? 0.0);
          if (r.loser != null) {
            if (r.loser == 'Team A' && _session.teamA.isNotEmpty) {
              final split = roundTotal / _session.teamA.length;
              for (final p in _session.teamA) {
                liabilities[p] = (liabilities[p] ?? 0.0) + split;
              }
            } else if (r.loser == 'Team B' && _session.teamB.isNotEmpty) {
              final split = roundTotal / _session.teamB.length;
              for (final p in _session.teamB) {
                liabilities[p] = (liabilities[p] ?? 0.0) + split;
              }
            } else {
              liabilities[r.loser!] = (liabilities[r.loser!] ?? 0.0) + roundTotal;
            }
          }
        }
      } else {
        final split = _gameCharge / (_session.allPlayers.isEmpty ? 1 : _session.allPlayers.length);
        for (final p in _session.allPlayers) {
          liabilities[p] = (liabilities[p] ?? 0.0) + split;
        }
      }

      for (final o in _session.orders) {
        if (o.playerName != null && liabilities.containsKey(o.playerName)) {
          liabilities[o.playerName!] = (liabilities[o.playerName!] ?? 0.0) + o.total;
        } else if (_session.allPlayers.isNotEmpty) {
          final split = o.total / _session.allPlayers.length;
          for (final p in _session.allPlayers) {
            liabilities[p] = (liabilities[p] ?? 0.0) + split;
          }
        }
      }

      final totalComputed = liabilities.values.fold<double>(0.0, (s, v) => s + v);
      final diff = totalToSplit - totalComputed;
      if (diff.abs() > 0.01 && _session.allPlayers.isNotEmpty) {
        final adj = diff / _session.allPlayers.length;
        for (final p in _session.allPlayers) {
          liabilities[p] = (liabilities[p] ?? 0.0) + adj;
        }
      }
    }

    setState(() {
      _customLiabilities = liabilities;
    });
  }'''

content = content.replace(init_method_old, init_method_new)
content = calc_liabilities_pattern.sub('', content)

# Update references from _calculatedLiabilities to _customLiabilities
content = content.replace('_calculatedLiabilities', '_customLiabilities')

# We need to make _buildSplitLiabilityTable editable
# Find _buildSplitLiabilityTable and replace
split_table_pattern = re.compile(r'  Widget _buildSplitLiabilityTable\(ThemeData theme\) \{.*?(?=  IconData _paymentIcon)', re.DOTALL)

split_table_new = '''  Widget _buildSplitLiabilityTable(ThemeData theme) {
    final liabilities = _customLiabilities;
    final players = _session.allPlayers;
    
    // Sum validation
    final currentSum = liabilities.values.fold<double>(0.0, (s, v) => s + v);
    final diff = (_grandTotal - currentSum).abs();
    final isBalanced = diff < 0.5; // Small tolerance

    return Column(
      children: [
        if (!isBalanced)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: AppColors.error),
                const Gap(8),
                Expanded(
                  child: Text(
                    'Split amounts (₹) do not equal the grand total (₹).',
                    style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        _SectionCard(
          children: players.map((player) {
            final amount = liabilities[player] ?? 0.0;
            final selectedMethod = _playerPaymentMethods[player] ?? PaymentMethod.cash;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(player, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          initialValue: amount == 0 ? '0' : amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2),
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.currency_rupee, size: 16),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          onChanged: (val) {
                            setState(() {
                              _customLiabilities[player] = double.tryParse(val) ?? 0.0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  Row(
                    children: PaymentMethod.values.map((method) {
                      final isSelected = selectedMethod == method;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _playerPaymentMethods[player] = method),
                          child: Container(
                            margin: EdgeInsets.only(right: method != PaymentMethod.credit ? 8 : 0),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary : theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected ? null : Border.all(color: theme.colorScheme.outlineVariant),
                            ),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_paymentIcon(method), size: 16, color: isSelected ? Colors.white : theme.colorScheme.onSurfaceVariant),
                                const Gap(4),
                                Text(method.displayName, style: TextStyle(color: isSelected ? Colors.white : theme.colorScheme.onSurface, fontWeight: FontWeight.w600, fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  if (player != players.last) const Divider(height: 24),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

'''
content = split_table_pattern.sub(split_table_new, content)

# We also need to disable the "Record Payment" button if not balanced.
# Let's find: onPressed: _isProcessing ? null : _confirmPayment,
# And change to: onPressed: (_isProcessing || !isBalanced) ? null : _confirmPayment,
# We need to compute isBalanced in uild
build_start = "  Widget build(BuildContext context) {"
build_start_new = '''  Widget build(BuildContext context) {
    final currentSum = _customLiabilities.values.fold<double>(0.0, (s, v) => s + v);
    final isBalanced = (_grandTotal - currentSum).abs() < 0.5;'''
content = content.replace(build_start, build_start_new)

confirm_btn_old = "onPressed: _isProcessing ? null : _confirmPayment,"
confirm_btn_new = "onPressed: (_isProcessing || (_isMultiRoundTP || _session.gameType != GameType.standard) && !isBalanced) ? null : _confirmPayment,"
content = content.replace(confirm_btn_old, confirm_btn_new)

# Also check _isMultiRoundTP references to allow splitting for Race and Rummy
# old: _isMultiRoundTP ? _buildSplitLiabilityTable(theme) : _buildSinglePaymentSelection(theme),
multi_round_check_old = "if (_isMultiRoundTP) ...["
multi_round_check_new = "if (_isMultiRoundTP || _session.gameType != GameType.standard) ...["
content = content.replace(multi_round_check_old, multi_round_check_new)

# And in _confirmPayment:
# final finalSession = _isMultiRoundTP
confirm_split_old = "final finalSession = _isMultiRoundTP"
confirm_split_new = "final finalSession = (_isMultiRoundTP || _session.gameType != GameType.standard)"
content = content.replace(confirm_split_old, confirm_split_new)

# one more _isMultiRoundTP check inside the confirm button:
# (_paymentMethod == PaymentMethod.credit || (_isMultiRoundTP && _playerPaymentMethods.values.contains(PaymentMethod.credit)))
btn_text_check_old = "(_isMultiRoundTP && _playerPaymentMethods.values.contains(PaymentMethod.credit))"
btn_text_check_new = "((_isMultiRoundTP || _session.gameType != GameType.standard) && _playerPaymentMethods.values.contains(PaymentMethod.credit))"
content = content.replace(btn_text_check_old, btn_text_check_new)

with open('lib/features/games/presentation/screens/billing_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
