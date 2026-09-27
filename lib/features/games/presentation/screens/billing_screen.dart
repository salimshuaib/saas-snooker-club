import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/routes/app_router.dart';
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';
import 'package:snooker_club/core/utils/billing_utils.dart';

import 'package:snooker_club/core/models/audit_log.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/features/authentication/providers/auth_providers.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/payer_selection_widget.dart';
import 'package:snooker_club/features/games/presentation/widgets/player_split_payment_sheet.dart';
import 'package:snooker_club/features/games/presentation/widgets/pending_bill_customer_sheet.dart';
import 'package:snooker_club/features/credit/presentation/widgets/player_search_field.dart';
import 'package:snooker_club/features/games/presentation/widgets/upi_qr_dialog.dart';
import 'package:snooker_club/features/games/presentation/widgets/audit_log_sheet.dart';
import 'package:snooker_club/features/games/presentation/widgets/orders_sheet.dart';

class BillingScreen extends ConsumerStatefulWidget {
  final GameSession session;

  const BillingScreen({super.key, required this.session});

  @override
  ConsumerState<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends ConsumerState<BillingScreen> {
  late GameSession _session;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  String? _PlayerProfileName;
  final Map<String, String> _renamedPlayers = {};
  late Map<String, Map<PaymentMethod, double>> _playerPaymentSplits;
  late Map<String, double> _customLiabilities;
  bool _isProcessing = false;
  bool _isRefreshing = false;
  bool _isTimeManuallyEdited = false;

  late List<String> _selectedPayers;
  double _discountAmount = 0.0;
  bool _hasDiscount = false;

  late TextEditingController _discountController;
  late TextEditingController _discountPercentController;
  late TextEditingController _discountedGameController;

  final Map<String, TextEditingController> _liabilityControllers = {};

  bool _liabilitiesInitialized = false;

  @override
  void initState() {
    super.initState();
    _session = widget.session.endTime == null 
        ? widget.session.copyWith(endTime: DateTime.now()) 
        : widget.session;
    _selectedPayers = List.from(_session.selectedPayers ?? _session.allPlayers);
    _discountAmount = _session.discountAmount ?? 0.0;
    _hasDiscount = _discountAmount > 0;

    _discountController = TextEditingController(
      text: _discountAmount == 0 ? '' : _discountAmount.toStringAsFixed(0),
    );
    // Calculate initial percent if amount exists
    double initialPercent = 0.0;
    // We cannot use _gameCharge here because it requires context for appSettings,
    // so we will just initialize empty and let the UI handle it or we can calculate base.
    _discountPercentController = TextEditingController();
    _discountedGameController = TextEditingController();

    _playerPaymentSplits = {
      for (final p in _session.allPlayers) p: {PaymentMethod.cash: 0.0},
    };
  }

  @override
  void dispose() {
    _discountController.dispose();
    _discountPercentController.dispose();
    _discountedGameController.dispose();
    for (final c in _liabilityControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _editTime(bool isStart) async {
    final currentDt = isStart ? _session.startTime : _session.endTime!;
    final picked = await showTimePicker(
      context: context,
      initialEntryMode: TimePickerEntryMode.input,
      initialTime: TimeOfDay.fromDateTime(currentDt),
    );
    if (picked != null) {
      setState(() {
        _isTimeManuallyEdited = true;
        
        // Zero out seconds to ensure clean exact minutes duration math
        final cleanStart = DateTime(
          _session.startTime.year,
          _session.startTime.month,
          _session.startTime.day,
          _session.startTime.hour,
          _session.startTime.minute,
          0,
        );
        final cleanEnd = _session.endTime != null ? DateTime(
          _session.endTime!.year,
          _session.endTime!.month,
          _session.endTime!.day,
          _session.endTime!.hour,
          _session.endTime!.minute,
          0,
        ) : null;

        final newDt = DateTime(
          currentDt.year,
          currentDt.month,
          currentDt.day,
          picked.hour,
          picked.minute,
          0,
        );
        if (isStart) {
          _session = _session.copyWith(startTime: newDt, endTime: cleanEnd);
        } else {
          _session = _session.copyWith(startTime: cleanStart, endTime: newDt);
        }
        _initializeLiabilities();
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_liabilitiesInitialized) {
      _initializeLiabilities();
      _liabilitiesInitialized = true;
    }
  }

  void _showAddPlayerDialog() {
    PlayerSelection? newPlayerSelection;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Player to Bill'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerSearchField(
                hint: 'Player Name',
                onSelected: (sel) {
                  newPlayerSelection = sel;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = newPlayerSelection?.name.trim();
                if (name != null && name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    ).then((playerName) {
      if (playerName != null && playerName is String) {
        setState(() {
          final newTeamA = List<String>.from(_session.teamA)..add(playerName);
          _session = _session.copyWith(teamA: newTeamA);

          _playerPaymentSplits[playerName] = {PaymentMethod.cash: 0.0};
          _liabilityControllers[playerName] = TextEditingController();

          _initializeLiabilities();
        });
      }
    });
  }

  Future<void> _showAddOrderSheet() async {
    final updated = await showModalBottomSheet<AddItemsResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => OrdersSheet(
        players: _session.allPlayers,
        currentOrders: _session.orders,
        currentManualGameCharges: _session.manualGameCharges,
        enableGamesTab: true,
      ),
    );

    if (updated != null && mounted) {
      final staffName = ref.read(currentStaffProvider).value?.name ?? 'Admin';
      final List<AuditLog> newLogs = List.from(_session.auditLogs);

      final oldMap = <String, int>{};
      for (final o in _session.orders) {
        final key = '${o.productId}_${o.playerName ?? ""}';
        oldMap[key] = (oldMap[key] ?? 0) + o.quantity;
      }
      final newMap = <String, int>{};
      final nameMap = <String, String>{};
      for (final o in updated.orders) {
        final key = '${o.productId}_${o.playerName ?? ""}';
        newMap[key] = (newMap[key] ?? 0) + o.quantity;
        nameMap[key] = o.productName;
      }

      for (final key in newMap.keys) {
        final oldQty = oldMap[key] ?? 0;
        final newQty = newMap[key]!;
        if (newQty > oldQty) {
          final diff = newQty - oldQty;
          newLogs.add(AuditLog(
            id: '${DateTime.now().millisecondsSinceEpoch}_add_$key',
            editedBy: staffName,
            timestamp: DateTime.now(),
            field: 'Order Added',
            previousValue: '-',
            newValue: '$diff x ${nameMap[key]}',
          ));
        } else if (newQty < oldQty) {
          final diff = oldQty - newQty;
          newLogs.add(AuditLog(
            id: '${DateTime.now().millisecondsSinceEpoch}_rem_$key',
            editedBy: staffName,
            timestamp: DateTime.now(),
            field: 'Order Removed',
            previousValue: '-',
            newValue: '$diff x ${nameMap[key]}',
          ));
        }
      }
      for (final key in oldMap.keys) {
        if (!newMap.containsKey(key)) {
          final productName = _session.orders.firstWhere((o) => '${o.productId}_${o.playerName ?? ""}' == key).productName;
          newLogs.add(AuditLog(
            id: '${DateTime.now().millisecondsSinceEpoch}_rem_$key',
            editedBy: staffName,
            timestamp: DateTime.now(),
            field: 'Order Removed',
            previousValue: '-',
            newValue: '${oldMap[key]} x $productName',
          ));
        }
      }

      setState(() {
              final oldGames = <String, ManualGameCharge>{};
      for (final g in _session.manualGameCharges) {
        oldGames[g.id] = g;
      }
      final newGames = <String, ManualGameCharge>{};
      for (final g in updated.manualGameCharges) {
        newGames[g.id] = g;
      }

      for (final g in newGames.values) {
        if (!oldGames.containsKey(g.id)) {
          newLogs.add(AuditLog(
            id: '${DateTime.now().millisecondsSinceEpoch}_add_${g.id}',
            editedBy: staffName,
            timestamp: DateTime.now(),
            field: 'Game Added',
            previousValue: '-',
            newValue: '${g.tableName} - ${g.gameType.displayName}',
          ));
        }
      }
      for (final g in oldGames.values) {
        if (!newGames.containsKey(g.id)) {
          newLogs.add(AuditLog(
            id: '${DateTime.now().millisecondsSinceEpoch}_rem_${g.id}',
            editedBy: staffName,
            timestamp: DateTime.now(),
            field: 'Game Removed',
            previousValue: '-',
            newValue: '${g.tableName} - ${g.gameType.displayName}',
          ));
        }
      }

      _session = _session.copyWith(orders: updated.orders, manualGameCharges: updated.manualGameCharges, auditLogs: newLogs);
        _initializeLiabilities();
      });
    }
  }

  void _removePlayer(String player) {
    if (_session.allPlayers.length <= 1) return;
    
    setState(() {
      final newTeamA = List<String>.from(_session.teamA)..remove(player);
      final newTeamB = List<String>.from(_session.teamB)..remove(player);
      _session = _session.copyWith(teamA: newTeamA, teamB: newTeamB);
      
      _selectedPayers.remove(player);
      _playerPaymentSplits.remove(player);
      _liabilityControllers.remove(player);
      _customLiabilities.remove(player);
      
      _initializeLiabilities();
    });
  }

  Future<void> _editPlayer(String oldName) async {
    PlayerSelection? newPlayerSelection = PlayerSelection(name: oldName);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Player Name'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              PlayerSearchField(
                hint: 'Player Name',
                initialSelection: newPlayerSelection,
                onSelected: (sel) {
                  newPlayerSelection = sel;
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                final name = newPlayerSelection?.name.trim();
                if (name != null && name.isNotEmpty) {
                  Navigator.pop(context, name);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    if (newName != null && newName != oldName) {
        setState(() {
          final newTeamA = List<String>.from(_session.teamA);
          final aIndex = newTeamA.indexOf(oldName);
          if (aIndex != -1) newTeamA[aIndex] = newName;

          final newTeamB = List<String>.from(_session.teamB);
          final bIndex = newTeamB.indexOf(oldName);
          if (bIndex != -1) newTeamB[bIndex] = newName;

          _session = _session.copyWith(teamA: newTeamA, teamB: newTeamB);

          if (_selectedPayers.contains(oldName)) {
            _selectedPayers.remove(oldName);
            _selectedPayers.add(newName);
          }

          final splits = _playerPaymentSplits.remove(oldName);
          _playerPaymentSplits[newName] = splits ?? {PaymentMethod.cash: 0.0};

          final controller = _liabilityControllers.remove(oldName);
          _liabilityControllers[newName] = controller ?? TextEditingController();

          if (_customLiabilities.containsKey(oldName)) {
            final liab = _customLiabilities.remove(oldName);
            _customLiabilities[newName] = liab!;
          }

          _initializeLiabilities();
        });
      }
  }

  Future<void> _showManagePayersDialog() async {
    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Manage Payers'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _session.allPlayers.length,
                  itemBuilder: (context, index) {
                    final player = _session.allPlayers[index];
                    return ListTile(
                      title: Text(player),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () async {
                              await _editPlayer(player);
                              if (mounted) setStateDialog(() {});
                            },
                          ),
                          if (_session.allPlayers.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.red),
                              onPressed: () {
                                _removePlayer(player);
                                setStateDialog(() {});
                              },
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Done'),
                )
              ],
            );
          },
        );
      },
    );
  }

  void _initializeLiabilities() {
    final Map<String, double> liabilities = {
      for (final p in _session.allPlayers) p: 0.0,
    };

    if (_session.allPlayers.isEmpty) {
      setState(() => _customLiabilities = liabilities);
      return;
    }

    final double discountedGame = _gameCharge - _discountAmount;

    if (_selectedPayers.isNotEmpty) {
      final rawShare = discountedGame / _selectedPayers.length;
      double roundedShare = BillingUtils.roundAmount(rawShare);

      // Protect minimum bill from split rounding loss
      final expectedMinimum = _session.isMinimumBillEnabled 
          ? (_session.minimumBillAmount - _discountAmount) 
          : 0.0;
      
      while ((roundedShare * _selectedPayers.length) < expectedMinimum) {
        roundedShare += 5.0;
      }

      for (final p in _selectedPayers) {
        liabilities[p] = roundedShare;
      }
    }

    final splitGroup = _selectedPayers.isNotEmpty ? _selectedPayers.toList() : _session.allPlayers.toList();

    for (final o in _session.orders) {
      if (o.playerName != null && liabilities.containsKey(o.playerName)) {
        liabilities[o.playerName!] =
            (liabilities[o.playerName!] ?? 0.0) + o.total;
      } else {
        final split = o.total / splitGroup.length;
        for (final p in splitGroup) {
          liabilities[p] = (liabilities[p] ?? 0.0) + split;
        }
      }
    }

    for (final g in _session.manualGameCharges) {
      final split = g.calculatedAmount / splitGroup.length;
      for (final p in splitGroup) {
        liabilities[p] = (liabilities[p] ?? 0.0) + split;
      }
    }

    for (final p in _session.allPlayers) {
      final amount = liabilities[p] ?? 0.0;
      final textValue = amount == 0
          ? '0'
          : amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);

      if (!_liabilityControllers.containsKey(p)) {
        _liabilityControllers[p] = TextEditingController(text: textValue);
      } else if (_liabilityControllers[p]!.text != textValue) {
        _liabilityControllers[p]!.text = textValue;
      }
    }

    setState(() {
      _customLiabilities = liabilities;
      for (final p in _session.allPlayers) {
        final amount = liabilities[p] ?? 0.0;
        final currentSplits =
            _playerPaymentSplits[p] ?? {PaymentMethod.cash: amount};
        if (currentSplits.length == 1) {
          _playerPaymentSplits[p] = {currentSplits.keys.first: amount};
        } else {
          _playerPaymentSplits[p] = {PaymentMethod.cash: amount};
        }
      }
    });
  }

  bool get _isMultiPayer =>
      _selectedPayers.length > 1 ||
      (_selectedPayers.isEmpty && _session.allPlayers.length > 1);

  GameChargeBreakdown get _breakdown {
    final appSettings = ref.read(appSettingsProvider);
    final tables = ref.read(resolvedTablesProvider);
    final table = tables.firstWhere(
      (t) => t.id == _session.tableId,
      orElse: () => TableModel(id: _session.tableId, name: _session.tableName, type: _session.tableType),
    );

    return TablePricingConfig.calculateCharge(
      table: table,
      gameType: _session.gameType,
      billingType: _session.billingType,
      activeSeconds: _session.activeSeconds,
      framesPlayed: math.max(_session.framesPlayed, _session.totalFrames),
      pricingConfig: _session.pricingSnapshot ?? appSettings.pricing,
      gameConfig: _session.gameSettingsSnapshot ?? appSettings.game,
      completedRounds: _session.rounds,
      customPrice: _session.customPrice,
      customExtraCharge: _session.customExtraCharge,
      playersCount: _session.playerIds.length,
      coinQuantity: _session.coinQuantity,
      customMinutes: _session.customMinutes,
      isMinimumBillEnabled: _session.isMinimumBillEnabled,
      minimumBillAmount: _session.minimumBillAmount,
    );
  }

  double get _gameCharge => _breakdown.totalCharge;
  double get _baseGameCharge => _breakdown.baseCharge;
  int get _overtimeMinutes => _breakdown.overtimeMinutes;
  double get _overtimeCharge => _breakdown.overtimeCharge;

  double get _manualGamesTotal => _session.manualGameCharges.fold<double>(0, (s, g) => s + g.calculatedAmount);
    
  double get _ordersTotal =>
      _session.orders.fold<double>(0, (s, o) => s + o.total);

  double get _discountedGameCharge => _gameCharge - _discountAmount;

  double get _grandTotal => _gameCharge + _ordersTotal + _manualGamesTotal;

  double get _finalTotal => _discountedGameCharge + _ordersTotal + _manualGamesTotal;

  double get _roundedTotal {
    if (_session.tableType == TableType.arcade) {
      return _finalTotal;
    }
    
    final expectedMinimum = _session.isMinimumBillEnabled 
        ? (_session.minimumBillAmount - _discountAmount) 
        : 0.0;

    if (_isMultiPayer) {
      if (_selectedPayers.isEmpty) return _finalTotal;
      final rawShare = _discountedGameCharge / _selectedPayers.length;
      double roundedShare = BillingUtils.roundAmount(rawShare);
      
      // Protect minimum bill from split rounding loss
      while ((roundedShare * _selectedPayers.length) < expectedMinimum) {
        roundedShare += 5.0;
      }
      
      return (roundedShare * _selectedPayers.length) + _ordersTotal + _manualGamesTotal;
    }
    
    // Single payer: Round the discounted game charge, then add exact orders
    double roundedGame = BillingUtils.roundAmount(_discountedGameCharge);
    
    // Protect minimum bill from rounding loss
    while (roundedGame < expectedMinimum) {
      roundedGame += 5.0;
    }
    
    return roundedGame + _ordersTotal + _manualGamesTotal;
  }

  String _formatDuration(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return seconds >= 3600 ? '$h:$m:$s' : '$m:$s';
  }

  int get _activePayerCount {
    if ((_isMultiPayer || _session.gameType != GameType.standard)) {
      return _customLiabilities.values.where((v) => v > 0).length;
    }
    return _customLiabilities.values.where((v) => v > 0).length;
  }

  bool get _hasCredit {
    if ((_isMultiPayer || _session.gameType != GameType.standard)) {
      return _playerPaymentSplits.entries.any(
        (e) => (e.value[PaymentMethod.credit] ?? 0.0) > 0.0,
      );
    }
    return _paymentMethod == PaymentMethod.credit;
  }

  String get _ctaLabel {
    if (_isMultiPayer) {
      return 'Mark Payment Complete';
    } else {
      if (_hasCredit) {
        return 'Record Payment & Credit';
      }
      return 'Confirm Payment (\u20B9${_roundedTotal.toStringAsFixed(0)})';
    }
  }

  Color get _ctaColor {
    if (_isMultiPayer) {
      return AppColors.primary;
    }
    return _hasCredit ? AppColors.creditStatus : AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final appSettings = ref.watch(appSettingsProvider);
    final tables = ref.watch(tablesProvider).value ?? [];
    final table = tables.firstWhere(
      (t) => t.id == _session.tableId,
      orElse: () => TableModel(id: _session.tableId, name: _session.tableName, type: _session.tableType),
    );
    final currentSum = _customLiabilities.values.fold<double>(
      0.0,
      (s, v) => s + v,
    );
    final isBalanced = (_roundedTotal - currentSum).abs() < 0.5;
    final theme = Theme.of(context);
    final dtFmt = DateFormat('d MMM, hh:mm a');

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Cancel Transaction?'),
            content: const Text(
              'Are you sure you want to go back? This game will remain open and unpaid.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('No'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                child: const Text('Yes, Go Back'),
              ),
            ],
          ),
        );
        if (shouldPop == true && mounted) {
          FocusScope.of(context).unfocus();
          await Future.delayed(const Duration(milliseconds: 150));
          if (mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Bill'),
          centerTitle: false,
          actions: [
            if (_session.auditLogs.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: 'Audit Log',
                onPressed: () => showAuditLogSheet(context, _session),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Session Summary ──
              _ExpandableSessionCard(
                session: _session,
                dtFmt: dtFmt,
                durationStr: _formatDuration(_session.activeSeconds),
                onEditStart: () => _editTime(true),
                onEditEnd: () => _editTime(false),
              ),
              const Gap(16),

              // ── Round ── Frame Summary ──
              if (_session.rounds.isNotEmpty) ...[
                Text(
                  'Round / Frame Summary',
                  style: theme.textTheme.titleMedium,
                ),
                const Gap(8),
                _SectionCard(
                  children: [
                    ..._session.rounds.map(
                      (r) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                r.framePayers == null
                                    ? 'Frame ${r.roundNumber} · ${(r.durationSeconds ?? 0) ~/ 60} mins${(r.overtimeMinutes ?? 0) > 0 ? " (+${r.overtimeMinutes}m OT)" : ""}'
                                    : 'Frame ${r.roundNumber} · Payers: ${r.framePayers!.join(', ')}${(r.overtimeMinutes ?? 0) > 0 ? " (+${r.overtimeMinutes}m OT)" : ""}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '\u20B9${(r.roundCost + (r.overtimeCharge ?? 0.0)).toStringAsFixed(2)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(16),
              ],

              //             // ─── Payer Selection ───
              PayerSelectionWidget(
                allPlayers: _session.allPlayers,
                selectedPayers: _selectedPayers,
                onAddPlayer: _showAddPlayerDialog,
                onManagePayers: _showManagePayersDialog,
                onChanged: (newPayers) {
                  setState(() {
                    _selectedPayers = newPayers;
                  });
                  _initializeLiabilities();
                },
              ),
              const Gap(16),

              // ── Additional Games ──
              if (_session.manualGameCharges.isNotEmpty) ...[
                Text('Additional Games', style: theme.textTheme.titleMedium),
                const Gap(8),
                _SectionCard(
                  children: [
                    ..._session.manualGameCharges.grouped().map(
                      (group) {
                        final g = group.charge;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${group.quantity}x ${g.tableName} - ${g.gameType.displayName}',
                                  style: theme.textTheme.bodyMedium,
                                ),
                              ),
                              Text(
                                '\u20B9${group.totalAmount.toStringAsFixed(0)}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                    ),
                  ],
                ),
                const Gap(16),
              ],

              // ── Orders ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Orders', style: theme.textTheme.titleMedium),
                  TextButton.icon(
                    onPressed: _showAddOrderSheet,
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Item'),
                  ),
                ],
              ),
              const Gap(8),
              if (_session.orders.isNotEmpty) ...[
                _SectionCard(
                  children: [
                    ..._session.orders.map(
                      (o) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${o.quantity}x ${o.productName}${o.playerName != null ? ' (${o.playerName})' : ''}',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '\u20B9${o.total.toStringAsFixed(0)}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const Gap(16),

              // ── Bill Summary ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Bill Summary', style: theme.textTheme.titleMedium),
                  if (widget.session.endTime == null && !_isTimeManuallyEdited)
                    _isRefreshing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: const Icon(Icons.refresh, size: 20),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            tooltip: 'Refresh live duration & bill',
                            onPressed: () async {
                              setState(() => _isRefreshing = true);
                              await Future.delayed(
                                  const Duration(milliseconds: 300));
                              if (!mounted) return;
                              setState(() {
                                _session = _session.copyWith(
                                    endTime: DateTime.now());
                                _initializeLiabilities();
                                _isRefreshing = false;
                              });
                            },
                          ),
                ],
              ),
              const Gap(8),
              _SectionCard(
                children: [
                  if (!appSettings.game.hideBillingDetails) ...[
                    if (_session.billingType == BillingType.perFrame) ...[
                      _InfoRow(
                        label: 'Frame Charges',
                        value: '\u20B9${_baseGameCharge.toStringAsFixed(2)}',
                      ),
                      _InfoRow(
                        label: 'Grace Period',
                        value: _session.tableType == TableType.indianPool
                            ? '${ref.read(appSettingsProvider).game.indianPoolGracePeriodMinutes} Mins / Frame'
                            : _session.tableType == TableType.americanPool
                            ? '${ref.read(appSettingsProvider).game.americanPoolGracePeriodMinutes} Mins / Frame'
                            : 'Not Applicable',
                      ),
                    ] else ...[
                      if (_session.billingType == BillingType.perMinute)
                        _InfoRow(
                          label: 'Rate',
                          value:
                              '\u20B9${(_session.customPrice ?? TablePricingConfig.getPerMinutePrice(table, _session.gameType, _session.pricingSnapshot ?? appSettings.pricing)).toStringAsFixed(2)} / min',
                        ),
                      _InfoRow(
                        label: 'Base Charge',
                        value: '\u20B9${_baseGameCharge.toStringAsFixed(2)}',
                      ),
                    ],
                    if (_overtimeMinutes > 0) ...[
                      _InfoRow(
                        label: 'Overtime (${_overtimeMinutes} mins)',
                        value: '\u20B9${_overtimeCharge.toStringAsFixed(2)}',
                      ),
                    ],
                    const Divider(height: 16),
                    _InfoRow(
                      label: 'Total Game Charge',
                      value: '\u20B9${_gameCharge.toStringAsFixed(2)}',
                    ),
                  ],
                  if (_ordersTotal > 0)
                    _InfoRow(
                      label: 'Orders Total',
                      value: '\u20B9${_ordersTotal.toStringAsFixed(2)}',
                    ),
                  // ── Discount ──
                  const Gap(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Apply Discount', style: theme.textTheme.titleSmall),
                      Switch(
                        value: _hasDiscount,
                        onChanged: (val) {
                          setState(() {
                            _hasDiscount = val;
                            if (!val) {
                              _discountAmount = 0.0;
                              _discountPercentController.clear();
                              _discountController.clear();
                              _discountedGameController.clear();
                              _initializeLiabilities();
                            } else {
                              _discountedGameController.text = _gameCharge.toStringAsFixed(0);
                            }
                          });
                        },
                      ),
                    ],
                  ),
                  if (_hasDiscount) ...[
                    const Gap(12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _discountPercentController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: '%',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (val) {
                              final percent = double.tryParse(val) ?? 0.0;
                              final amount = (_gameCharge * (percent / 100));
                              setState(() {
                                _discountAmount = amount;
                                _discountController.text = amount == 0
                                    ? ''
                                    : amount.toStringAsFixed(0);
                                final finalCharge = _gameCharge - amount;
                                _discountedGameController.text = finalCharge == 0
                                    ? ''
                                    : finalCharge.toStringAsFixed(0);
                              });
                              _initializeLiabilities();
                            },
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: TextFormField(
                            controller: _discountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Amount',
                              prefixText: '\u20B9',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (val) {
                              final amount = double.tryParse(val) ?? 0.0;
                              final percent = _gameCharge > 0
                                  ? (amount / _gameCharge) * 100
                                  : 0.0;
                              setState(() {
                                _discountAmount = amount;
                                _discountPercentController.text = percent == 0
                                    ? ''
                                    : percent.toStringAsFixed(1);
                                final finalCharge = _gameCharge - amount;
                                _discountedGameController.text = finalCharge == 0
                                    ? ''
                                    : finalCharge.toStringAsFixed(0);
                              });
                              _initializeLiabilities();
                            },
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: TextFormField(
                            controller: _discountedGameController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Final Game',
                              prefixText: '\u20B9',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onChanged: (val) {
                              double finalGame = double.tryParse(val) ?? _gameCharge;
                              if (finalGame > _gameCharge) finalGame = _gameCharge;
                              if (finalGame < 0) finalGame = 0;
                              
                              final amount = _gameCharge - finalGame;
                              final percent = _gameCharge > 0
                                  ? (amount / _gameCharge) * 100
                                  : 0.0;
                                  
                              setState(() {
                                _discountAmount = amount;
                                _discountController.text = amount == 0
                                    ? ''
                                    : amount.toStringAsFixed(0);
                                _discountPercentController.text = percent == 0
                                    ? ''
                                    : percent.toStringAsFixed(1);
                              });
                              _initializeLiabilities();
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  const Divider(height: 16),

                  // ── Final Amounts ──
                  if (!appSettings.game.hideBillingDetails) ...[
                    if (_hasDiscount) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Discounted Game',
                            style: theme.textTheme.titleSmall,
                          ),
                          Text(
                            '\u20B9${_discountedGameCharge.toStringAsFixed(2)}',
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const Gap(4),
                    ],
                    if (_ordersTotal > 0) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Orders', style: theme.textTheme.titleSmall),
                          Text(
                            '\u20B9${_ordersTotal.toStringAsFixed(2)}',
                            style: theme.textTheme.titleSmall,
                          ),
                        ],
                      ),
                      const Gap(12),
                    ] else if (!_hasDiscount) ...[
                      // Add a small gap if both are hidden so the divider doesn't look too close
                      const Gap(8),
                    ],
                  ],
                  if (!appSettings.game.hideBillingDetails &&
                      (_roundedTotal - _finalTotal).abs() > 0.01) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rounding Adjustment',
                          style: theme.textTheme.titleSmall,
                        ),
                        Text(
                          '${(_roundedTotal - _finalTotal) > 0 ? '+' : '-'}\u20B9${(_roundedTotal - _finalTotal).abs().toStringAsFixed(2)}',
                          style: theme.textTheme.titleSmall,
                        ),
                      ],
                    ),
                    const Gap(12),
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Final Bill Amount',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '\u20B9${_roundedTotal.toStringAsFixed(0)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(16),

              // ── Payment Method ── Liability Distribution ──
              if (_isMultiPayer) ...[
                Text(
                  'Player Liabilities & Payment',
                  style: theme.textTheme.titleMedium,
                ),
                const Gap(8),
                _buildSplitLiabilityTable(theme),
                const Gap(32),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Payment Method', style: theme.textTheme.titleMedium),
                    (() {
                      final basePlayer = _selectedPayers.isNotEmpty
                          ? _selectedPayers.first
                          : _session.allPlayers.isEmpty
                          ? 'Guest'
                          : _session.allPlayers.first;
                      final isSingleDefault =
                          !_isMultiPayer &&
                          basePlayer.toLowerCase().startsWith('default');
                      final displayPlayer =
                          (isSingleDefault &&
                              _PlayerProfileName != null &&
                              _PlayerProfileName!.isNotEmpty)
                          ? _PlayerProfileName!
                          : basePlayer;
                      return Expanded(
                        child: Wrap(
                          alignment: WrapAlignment.end,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                          if (appSettings.business.upiId != null &&
                              appSettings.business.upiId!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: TextButton.icon(
                                onPressed: () {
                                  final splits = _playerPaymentSplits[basePlayer];
                                  final upiAmount = splits != null ? (splits[PaymentMethod.upi] ?? 0.0) : 0.0;
                                  final qrAmount = upiAmount > 0 ? upiAmount : _roundedTotal;
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => UpiQrDialog(
                                      upiId: appSettings.business.upiId!,
                                      payeeName: appSettings.business.clubName,
                                      amount: qrAmount,
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.qr_code_2, size: 16),
                                label: const Text(
                                  'Generate QR',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                          TextButton.icon(
                            onPressed: () {
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
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: const Icon(Icons.call_split, size: 16),
                            label: const Text('Payment Breakdown', style: TextStyle(fontSize: 12)),
                          ),
                        ],
                      ));
                    })(),
                  ],
                ),
                const Gap(8),
                Builder(
                  builder: (context) {
                    final player = _selectedPayers.isNotEmpty
                        ? _selectedPayers.first
                        : _session.allPlayers.isEmpty
                        ? 'Guest'
                        : _session.allPlayers.first;
                    final splits = _playerPaymentSplits[player] ?? {};
                    final isSplit = splits.keys.length > 1;

                    if (isSplit) {
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          splits.entries
                              .map(
                                (e) =>
                                    '₹${e.value.toStringAsFixed(e.value.truncateToDouble() == e.value ? 0 : 2)} ${e.key.displayName}',
                              )
                              .join(' + '),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return Row(
                      children: PaymentMethod.values.map((method) {
                        final isSelected =
                            (splits.isEmpty && _paymentMethod == method) ||
                            (splits.isNotEmpty && splits.keys.first == method);
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              if (method == PaymentMethod.credit &&
                                  !isSplit &&
                                  player.toLowerCase().startsWith('default')) {
                                _showCreditNameDialog(
                                  player,
                                  autoConfirm: false,
                                  setMethod: true,
                                );
                              } else {
                                setState(() {
                                  _paymentMethod = method;
                                  _playerPaymentSplits[player] = {
                                    method: _roundedTotal,
                                  };
                                  if (method == PaymentMethod.credit && !isSplit) {
                                    _PlayerProfileName = player;
                                  }
                                });
                              }
                            },
                            child: Container(
                              margin: EdgeInsets.only(
                                right: method != PaymentMethod.credit ? 8 : 0,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                                border: isSelected
                                    ? null
                                    : Border.all(
                                        color: theme.colorScheme.outlineVariant,
                                      ),
                              ),
                              alignment: Alignment.center,
                              child: Column(
                                children: [
                                  Icon(
                                    _paymentIcon(method),
                                    color: isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const Gap(4),
                                  Text(
                                    method.displayName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
                const Gap(32),
              ],

              // ── Confirm Button ──
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed:
                      (_isProcessing ||
                          (_isMultiPayer ||
                                  _session.gameType != GameType.standard) &&
                              !isBalanced)
                      ? null
                      : _confirmPayment,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    backgroundColor: _ctaColor,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          _ctaLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSplitLiabilityTable(ThemeData theme) {
    final appSettings = ref.watch(appSettingsProvider);
    final liabilities = _customLiabilities;
    final players = _session.allPlayers;

    // Sum validation
    final currentSum = liabilities.values.fold<double>(0.0, (s, v) => s + v);
    final diff = (_roundedTotal - currentSum).abs();
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
                    'Split amounts (\u20B9) do not equal the grand total (\u20B9).',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        _SectionCard(
          children: players.map((player) {
            final amount = liabilities[player] ?? 0.0;
            final splits =
                _playerPaymentSplits[player] ?? {PaymentMethod.cash: amount};
            final isSplit = splits.length > 1;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              _renamedPlayers[player] ?? player,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                            icon: const Icon(
                              Icons.edit,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onPressed: () => _showCreditNameDialog(
                              player,
                              autoConfirm: false,
                              setMethod: false,
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            constraints: const BoxConstraints(),
                            tooltip: 'Rename Player',
                          ),
                          const Gap(4),
                          Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              if (appSettings.business.upiId != null &&
                                  appSettings.business.upiId!.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: TextButton.icon(
                                    onPressed: () {
                                      final upiAmount = splits[PaymentMethod.upi] ?? 0.0;
                                      final qrAmount = upiAmount > 0 ? upiAmount : (liabilities[player] ?? 0.0);
                                      showDialog(
                                        context: context,
                                        builder: (ctx) => UpiQrDialog(
                                          upiId: appSettings.business.upiId!,
                                          payeeName:
                                              appSettings.business.clubName,
                                          amount: qrAmount,
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    icon: const Icon(
                                      Icons.qr_code_2,
                                      size: 16,
                                    ),
                                    label: const Text(
                                      'Generate QR',
                                      style: TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ),
                              TextButton.icon(
                                onPressed: () {
                                  showModalBottomSheet(
                                    context: context,
                                    isScrollControlled: true,
                                    builder: (ctx) => PlayerSplitPaymentSheet(
                                      playerName: player,
                                      totalLiability:
                                          liabilities[player] ?? 0.0,
                                      initialSplits: splits,
                                      onSplitsSaved: (newSplits) {
                                        setState(() {
                                          _playerPaymentSplits[player] =
                                              newSplits;
                                        });
                                      },
                                    ),
                                  );
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  minimumSize: Size.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                ),
                                icon: const Icon(Icons.call_split, size: 16),
                                label: const Text(
                                  'Payment Breakdown',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )),
                      SizedBox(
                        width: 120,
                        child: TextFormField(
                          controller: _liabilityControllers[player],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.currency_rupee,
                              size: 16,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          onChanged: (val) {
                            setState(() {
                              final newAmount = double.tryParse(val) ?? 0.0;
                              _customLiabilities[player] = newAmount;
                              final currentSplits =
                                  _playerPaymentSplits[player] ??
                                  {PaymentMethod.cash: newAmount};
                              if (currentSplits.length == 1) {
                                _playerPaymentSplits[player] = {
                                  currentSplits.keys.first: newAmount,
                                };
                              } else {
                                _playerPaymentSplits[player] = {
                                  PaymentMethod.cash: newAmount,
                                };
                              }
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const Gap(12),
                  if (isSplit)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        splits.entries
                            .map(
                              (e) =>
                                  '₹${e.value.toStringAsFixed(e.value.truncateToDouble() == e.value ? 0 : 2)} ${e.key.displayName}',
                            )
                            .join(' + '),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Row(
                      children: PaymentMethod.values.map((method) {
                        final isSelected = splits.keys.first == method;
                        return Expanded(
                          child: GestureDetector(
                            onTap: () {
                              final displayName =
                                  _renamedPlayers[player] ?? player;
                              if (method == PaymentMethod.credit &&
                                  displayName.toLowerCase().startsWith(
                                    'default',
                                  )) {
                                _showCreditNameDialog(
                                  player,
                                  autoConfirm: false,
                                  setMethod: true,
                                );
                              } else {
                                setState(
                                  () => _playerPaymentSplits[player] = {
                                    method: liabilities[player] ?? 0.0,
                                  },
                                );
                              }
                            },
                            child: Container(
                              margin: EdgeInsets.only(
                                right: method != PaymentMethod.credit ? 8 : 0,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.primary
                                    : theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                                border: isSelected
                                    ? null
                                    : Border.all(
                                        color: theme.colorScheme.outlineVariant,
                                      ),
                              ),
                              alignment: Alignment.center,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    _paymentIcon(method),
                                    size: 16,
                                    color: isSelected
                                        ? Colors.white
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const Gap(4),
                                  Text(
                                    method.displayName,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 11,
                                    ),
                                  ),
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

  IconData _paymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments;
      case PaymentMethod.upi:
        return Icons.qr_code_scanner;
      case PaymentMethod.credit:
        return Icons.credit_score;
    }
  }

  void _showCreditNameDialog(
    String defaultName, {
    bool autoConfirm = false,
    bool setMethod = false,
  }) {
    String initialText = '';
    if (!_isMultiPayer) {
      initialText =
          _PlayerProfileName != null &&
              !_PlayerProfileName!.toLowerCase().startsWith('default')
          ? _PlayerProfileName!
          : (defaultName.toLowerCase().startsWith('default')
                ? ''
                : defaultName);
    } else {
      final renamed = _renamedPlayers[defaultName];
      initialText =
          renamed != null && !renamed.toLowerCase().startsWith('default')
          ? renamed
          : (defaultName.toLowerCase().startsWith('default')
                ? ''
                : defaultName);
    }

    final nameCtrl = TextEditingController(text: initialText);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Customer Name for Credit'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(hintText: 'Enter real name'),
          autofocus: true,
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  if (!_isMultiPayer) {
                    _PlayerProfileName = nameCtrl.text.trim();
                  } else {
                    _renamedPlayers[defaultName] = nameCtrl.text.trim();
                  }
                  if (autoConfirm || setMethod) {
                    _paymentMethod = PaymentMethod.credit;
                    _playerPaymentSplits[defaultName] = {
                      PaymentMethod.credit: !_isMultiPayer
                          ? _roundedTotal
                          : (_customLiabilities[defaultName] ?? 0.0),
                    };
                  }
                });
                Navigator.pop(ctx);
                if (autoConfirm) {
                  // Wait for dialog exit animation to finish before navigating away
                  await Future.delayed(const Duration(milliseconds: 300));
                  if (mounted) {
                    _confirmPayment();
                  }
                }
              }
            },
            child: Text(autoConfirm ? 'Record Payment' : 'Save'),
          ),
        ],
      ),
    );
  }

  
  Future<void> _markAsPending(String customerId, String customerName) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final finalEndTime = _isTimeManuallyEdited
          ? _session.endTime ?? DateTime.now()
          : DateTime.now();
      
      final finalSession = _session.copyWith(
        endTime: finalEndTime,
        gameCharge: _gameCharge,
        baseGameCharge: _baseGameCharge,
        overtimeMinutes: _overtimeMinutes,
        overtimeCharge: _overtimeCharge,
        ordersTotal: _ordersTotal,
        
        grandTotal: _finalTotal,
        roundedAmount: _roundedTotal,
        finalAmount: _roundedTotal,
        discountAmount: _discountAmount,
        playerPaymentSplits: _playerPaymentSplits,
        playerLiabilities: _customLiabilities,
      );

      await ref
          .read(gamesRepositoryProvider)
          .markAsPendingBill(finalSession, customerId: customerId, customerName: customerName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill marked as pending for ' + customerName + '.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as pending: ' + e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showPendingBillCustomerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: PendingBillCustomerSheet(
          onCustomerSelected: (id, name) {
            Navigator.of(context).pop();
            _markAsPending(id, name);
          },
        ),
      ),
    );
  }

  Future<void> _confirmPayment() async {
    if (_isProcessing) return;

    final singlePayer = _selectedPayers.isNotEmpty
        ? _selectedPayers.first
        : _session.allPlayers.first;
    final isSplit = (_playerPaymentSplits[singlePayer]?.keys.length ?? 0) > 1;

    bool hasDefaultCredit = false;
    final isDefaultProfile =
        _PlayerProfileName == null ||
        _PlayerProfileName!.toLowerCase().startsWith('default');

    if (!_isMultiPayer && _session.gameType == GameType.standard) {
      if (!isSplit &&
          _paymentMethod == PaymentMethod.credit &&
          isDefaultProfile) {
        hasDefaultCredit = true;
      } else if (isSplit) {
        final splits = _playerPaymentSplits[singlePayer] ?? {};
        if (splits.containsKey(PaymentMethod.credit) &&
            splits[PaymentMethod.credit]! > 0) {
          if (isDefaultProfile &&
              singlePayer.toLowerCase().startsWith('default')) {
            hasDefaultCredit = true;
          }
        }
      }
    } else if (_isMultiPayer) {
      for (final player in _playerPaymentSplits.keys) {
        final splits = _playerPaymentSplits[player]!;
        if (splits.containsKey(PaymentMethod.credit) &&
            splits[PaymentMethod.credit]! > 0) {
          final displayName = _renamedPlayers[player] ?? player;
          if (displayName.toLowerCase().startsWith('default')) {
            hasDefaultCredit = true;
            break;
          }
        }
      }
    }

    if (hasDefaultCredit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the customer taking the credit.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    List<String> finalTeamA = List.from(_session.teamA);
    List<String> finalTeamB = List.from(_session.teamB);
    List<String>? finalPlayerIds = _session.playerIds != null
        ? List.from(_session.playerIds!)
        : null;
    Map<String, String>? finalPlayerIdentities =
        _session.playerIdentities != null
        ? Map.from(_session.playerIdentities!)
        : null;

    if (_isMultiPayer) {
      for (final entry in _renamedPlayers.entries) {
        final oldName = entry.key;
        final newName = entry.value;
        if (oldName == newName) continue;

        if (finalTeamA.contains(oldName)) {
          finalTeamA[finalTeamA.indexOf(oldName)] = newName;
        }
        if (finalTeamB.contains(oldName)) {
          finalTeamB[finalTeamB.indexOf(oldName)] = newName;
        }
        if (finalPlayerIdentities != null &&
            finalPlayerIdentities.containsKey(oldName)) {
          final oldId = finalPlayerIdentities.remove(oldName);
          if (finalPlayerIds != null && oldId != null)
            finalPlayerIds.remove(oldId);
        }

        if (_playerPaymentSplits.containsKey(oldName)) {
          _playerPaymentSplits[newName] = _playerPaymentSplits.remove(oldName)!;
        }
        if (_customLiabilities.containsKey(oldName)) {
          _customLiabilities[newName] = _customLiabilities.remove(oldName)!;
        }
      }
    } else {
      // Regardless of split or single method, if it was a default player and they renamed it,
      // apply the rename across all tracking objects to prevent ghost Khata accounts.
      final hasRenamedDefault =
          singlePayer.toLowerCase().startsWith('default') &&
          _PlayerProfileName != null &&
          _PlayerProfileName!.isNotEmpty &&
          _PlayerProfileName != singlePayer;

      if (hasRenamedDefault) {
        final creditPayer = _PlayerProfileName!;

        // 1. Rename in Team A/B
        if (finalTeamA.contains(singlePayer)) {
          finalTeamA[finalTeamA.indexOf(singlePayer)] = creditPayer;
        }
        if (finalTeamB.contains(singlePayer)) {
          finalTeamB[finalTeamB.indexOf(singlePayer)] = creditPayer;
        }
        if (finalPlayerIdentities != null &&
            finalPlayerIdentities.containsKey(singlePayer)) {
          final oldId = finalPlayerIdentities.remove(singlePayer);
          if (finalPlayerIds != null && oldId != null) {
            finalPlayerIds.remove(oldId);
          }
        }

        // 2. Rename in Splits/Liabilities if they were populated under the old default name
        if (isSplit && _playerPaymentSplits.containsKey(singlePayer)) {
          final existingSplit = _playerPaymentSplits.remove(singlePayer);
          if (existingSplit != null) {
            _playerPaymentSplits[creditPayer] = existingSplit;
          }
        }
        if (isSplit && _customLiabilities.containsKey(singlePayer)) {
          final existingLiab = _customLiabilities.remove(singlePayer);
          if (existingLiab != null) {
            _customLiabilities[creditPayer] = existingLiab;
          }
        }
      }

      if (!isSplit) {
        final creditPayer = hasRenamedDefault
            ? _PlayerProfileName!
            : singlePayer;
        _playerPaymentSplits.clear();
        _playerPaymentSplits[creditPayer] = {_paymentMethod: _roundedTotal};

        _customLiabilities.clear();
        _customLiabilities[creditPayer] = _roundedTotal;
      }
    }

    final finalEndTime = _session.endTime!;
    final finalDate = DateFormat('yyyy-MM-dd').format(finalEndTime);

    final List<AuditLog> updatedLogs = List.from(_session.auditLogs);
    final staff = ref.read(currentStaffProvider).value;
    final staffId = staff?.id ?? 'admin';
    final staffName = staff?.name ?? 'Admin';

    if (_isTimeManuallyEdited) {
      final editorName = staffName;
      
      final oldStart = widget.session.startTime;
      final newStart = _session.startTime;
      if (oldStart != newStart) {
        updatedLogs.add(AuditLog(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_start',
          editedBy: editorName,
          timestamp: DateTime.now(),
          field: 'Start Time',
          previousValue: DateFormat('hh:mm a').format(oldStart),
          newValue: DateFormat('hh:mm a').format(newStart),
        ));
      }
      
      final oldEnd = widget.session.endTime;
      final newEnd = _session.endTime!;
      if (oldEnd != newEnd) {
        updatedLogs.add(AuditLog(
          id: DateTime.now().millisecondsSinceEpoch.toString() + '_end',
          editedBy: editorName,
          timestamp: DateTime.now(),
          field: 'End Time',
          previousValue: oldEnd != null ? DateFormat('hh:mm a').format(oldEnd) : 'Live/Running',
          newValue: DateFormat('hh:mm a').format(newEnd),
        ));
      }
    }

    final paymentMethodLabel = isSplit 
        ? 'Split' 
        : _paymentMethod?.displayName ?? 'Paid';
        
    updatedLogs.add(AuditLog(
      id: '${DateTime.now().millisecondsSinceEpoch}_payment',
      editedBy: staffName,
      timestamp: DateTime.now(),
      field: 'Payment Processed',
      previousValue: '-',
      newValue: '₹${_roundedTotal.toStringAsFixed(2)} — $paymentMethodLabel',
    ));

    final finalSession = _session.copyWith(
      endTime: finalEndTime,
      auditLogs: updatedLogs,
      status: TableStatus.available,
      processedByUserId: staffId,
      processedByName: staffName,
      teamA: finalTeamA,
      teamB: finalTeamB,
      playerIds: finalPlayerIds,
      playerIdentities: finalPlayerIdentities,
      playerPaymentSplits: _playerPaymentSplits,
      playerLiabilities: _customLiabilities,
      gameCharge: _gameCharge,
      baseGameCharge: _baseGameCharge,
      overtimeMinutes: _overtimeMinutes,
      overtimeCharge: _overtimeCharge,
      ordersTotal: _ordersTotal,
      grandTotal: _grandTotal,
      roundedAmount: _roundedTotal,
      finalAmount: _roundedTotal,
      date: finalDate,
      paidBy:
          (_paymentMethod == PaymentMethod.credit && !_isMultiPayer && !isSplit)
          ? _PlayerProfileName
          : null,
      paymentMethod: (!isSplit) ? _paymentMethod : null,
    );

    try {
      final messenger = ScaffoldMessenger.of(context);
      await ref
          .read(gameSessionControllerProvider.notifier)
          .endGame(finalSession);
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Payment recorded. Table is now available.'),
            backgroundColor: AppColors.success,
          ),
        );
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          ref.read(appRouterProvider).go('/');
        }
        return;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
    if (mounted) {
      setState(() => _isProcessing = false);
    }
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Widget? trailing;

  const _InfoRow({required this.label, required this.value, this.trailing});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WinnerTile extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _WinnerTile({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.success.withValues(alpha: 0.1)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: AppColors.success, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.emoji_events : Icons.person_outline,
              color: isSelected
                  ? AppColors.success
                  : theme.colorScheme.onSurfaceVariant,
            ),
            const Gap(12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: isSelected
                      ? AppColors.success
                      : theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.success),
          ],
        ),
      ),
    );
  }
}

class _ExpandableSessionCard extends StatefulWidget {
  final GameSession session;
  final DateFormat dtFmt;
  final String durationStr;
  final VoidCallback? onEditStart;
  final VoidCallback? onEditEnd;

  const _ExpandableSessionCard({
    required this.session,
    required this.dtFmt,
    required this.durationStr,
    this.onEditStart,
    this.onEditEnd,
  });

  @override
  State<_ExpandableSessionCard> createState() => _ExpandableSessionCardState();
}

class _ExpandableSessionCardState extends State<_ExpandableSessionCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = widget.session;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () => setState(() => _isExpanded = !_isExpanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Table',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 6),
                        AnimatedRotation(
                          turns: _isExpanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: Icon(
                            Icons.expand_more,
                            size: 18,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      s.tableName,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              _InfoRow(label: 'Duration', value: widget.durationStr),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                alignment: Alignment.topCenter,
                child: _isExpanded
                    ? Column(
                        children: [
                          _InfoRow(
                            label: 'Billing',
                            value: s.billingType.displayName,
                          ),
                          _InfoRow(
                            label: 'Players',
                            value: s.allPlayers.join(', '),
                          ),
                          if (s.createdByName != null)
                            _InfoRow(
                              label: 'Started By',
                              value: s.createdByName!,
                            ),
                          _InfoRow(
                            label: 'Start Time',
                            value: widget.dtFmt.format(s.startTime),
                            trailing: widget.onEditStart != null
                                ? InkWell(
                                    onTap: widget.onEditStart,
                                    child: const Icon(Icons.edit, size: 16),
                                  )
                                : null,
                          ),
                          _InfoRow(
                            label: 'End Time',
                            value: widget.dtFmt.format(s.endTime!),
                            trailing: widget.onEditEnd != null
                                ? InkWell(
                                    onTap: widget.onEditEnd,
                                    child: const Icon(Icons.edit, size: 16),
                                  )
                                : null,
                          ),
                          if (s.billingType == BillingType.perFrame)
                            _InfoRow(
                              label: 'Frames',
                              value:
                                  '${s.framesPlayed > 0 ? s.framesPlayed : s.totalFrames}',
                            ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
