import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:snooker_club/core/providers/printer_provider.dart';
import 'package:snooker_club/core/services/receipt_formatter.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/widgets/cards/glass_card.dart';
import 'package:snooker_club/features/settings/presentation/widgets/settings_section_card.dart';

class PrinterSettingsScreen extends ConsumerStatefulWidget {
  const PrinterSettingsScreen({super.key});

  @override
  ConsumerState<PrinterSettingsScreen> createState() => _PrinterSettingsScreenState();
}

class _PrinterSettingsScreenState extends ConsumerState<PrinterSettingsScreen> {
  bool _isLoading = false;
  bool _isTesting = false;
  String? _connectingMac;
  List<BluetoothInfo> _pairedDevices = [];
  bool _isBluetoothEnabled = false;

  @override
  void initState() {
    super.initState();
    _initPrinterState();
  }

  Future<void> _initPrinterState() async {
    setState(() => _isLoading = true);

    final service = ref.read(bluetoothPrinterServiceProvider);
    final isEnabled = await service.isBluetoothAvailable();
    var isConnected = await service.isConnected;

    if (!isConnected && isEnabled) {
      final printerState = ref.read(printerSettingsProvider);
      if (printerState.savedMac != null) {
        isConnected = await ref.read(printerSettingsProvider.notifier).autoConnect();
      }
    } else {
      ref.read(printerSettingsProvider.notifier).setConnected(isConnected);
    }

    if (mounted) {
      setState(() {
        _isBluetoothEnabled = isEnabled;
      });
    }

    if (isEnabled) {
      await _refreshPairedDevices();
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshPairedDevices() async {
    setState(() => _isLoading = true);
    final service = ref.read(bluetoothPrinterServiceProvider);
    final isEnabled = await service.isBluetoothAvailable();
    final devices = await service.getPairedDevices();
    var isConnected = await service.isConnected;

    if (!isConnected && isEnabled) {
      final printerState = ref.read(printerSettingsProvider);
      if (printerState.savedMac != null) {
        isConnected = await ref.read(printerSettingsProvider.notifier).autoConnect();
      }
    } else {
      ref.read(printerSettingsProvider.notifier).setConnected(isConnected);
    }

    if (mounted) {
      setState(() {
        _isBluetoothEnabled = isEnabled;
        _pairedDevices = devices;
        _isLoading = false;
      });
    }
  }

  Future<void> _connectToDevice(BluetoothInfo device) async {
    setState(() => _connectingMac = device.macAdress);
    final service = ref.read(bluetoothPrinterServiceProvider);

    final success = await service.connect(device);
    if (!mounted) return;

    if (success) {
      await ref.read(printerSettingsProvider.notifier).saveConnectedPrinter(
            mac: device.macAdress,
            name: device.name,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connected to ${device.name}'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to connect to ${device.name}. Ensure it is turned on and in range.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }

    final isConnected = await service.isConnected;
    ref.read(printerSettingsProvider.notifier).setConnected(isConnected);
    if (mounted) {
      setState(() => _connectingMac = null);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _isLoading = true);
    await ref.read(printerSettingsProvider.notifier).clearSavedPrinter();
    if (mounted) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Printer disconnected')),
      );
    }
  }

  Future<void> _testPrint() async {
    setState(() => _isTesting = true);
    final service = ref.read(bluetoothPrinterServiceProvider);
    final paper = ref.read(printerSettingsProvider).paperWidth;

    final testBytes = ReceiptFormatter.buildTestReceipt(paper: paper);
    final success = await service.printBytes(testBytes);

    if (!mounted) return;
    setState(() => _isTesting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test receipt printed successfully!'),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Test print failed. Please check printer connection.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final printerState = ref.watch(printerSettingsProvider);
    final isConnected = printerState.isConnected;
    final savedMac = printerState.savedMac;
    final savedName = printerState.savedName;
    final autoPrint = printerState.autoPrint;
    final printCopies = printerState.printCopies;
    final paperWidth = printerState.paperWidth;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Thermal Printer'),
        actions: [
          IconButton(
            tooltip: 'Refresh Devices',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _refreshPairedDevices,
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  if (kIsWeb) ...[
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.info, size: 28),
                          const Gap(16),
                          Expanded(
                            child: Text(
                              'Direct Bluetooth thermal printing (e.g. DC Code M21) requires the Android app. On Web/browser, bill receipts can be saved as PDF or printed via the system print dialog.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),
                  ],

                  // Connection Status Card
                  _buildStatusCard(
                    theme: theme,
                    isConnected: isConnected,
                    savedName: savedName,
                    savedMac: savedMac,
                  ),

                  const Gap(8),

                  // Paired Devices Section
                  SettingsSectionCard(
                    title: 'Paired Bluetooth Devices',
                    icon: Icons.bluetooth_searching,
                    iconColor: AppColors.primary,
                    trailing: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : TextButton.icon(
                            icon: const Icon(Icons.refresh, size: 16),
                            label: const Text('Refresh'),
                            onPressed: _refreshPairedDevices,
                          ),
                    children: [
                      if (!_isBluetoothEnabled && !kIsWeb) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.bluetooth_disabled, color: AppColors.warning),
                              const Gap(8),
                              Expanded(
                                child: Text(
                                  'Bluetooth is turned off on this device. Please turn on Bluetooth and pair your printer in Android Settings.',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (_pairedDevices.isEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'No paired thermal printers found.',
                                style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              const Gap(6),
                              Text(
                                'To connect your DC Code M21:\n'
                                '1. Turn on your DC Code M21 printer.\n'
                                '2. Go to your Android tablet/phone Settings -> Bluetooth.\n'
                                '3. Pair with your printer (default PIN is usually 0000 or 1234).\n'
                                '4. Return here and tap "Refresh".',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _pairedDevices.length,
                          separatorBuilder: (_, _) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final device = _pairedDevices[index];
                            final isThisConnected = isConnected && savedMac == device.macAdress;
                            final isThisConnecting = _connectingMac == device.macAdress;

                            return ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: CircleAvatar(
                                backgroundColor: isThisConnected
                                    ? AppColors.success.withValues(alpha: 0.15)
                                    : theme.colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.print,
                                  color: isThisConnected ? AppColors.success : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              title: Text(
                                device.name.isEmpty ? 'Thermal Printer' : device.name,
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(device.macAdress),
                              trailing: isThisConnected
                                  ? const Chip(
                                      avatar: Icon(Icons.check_circle, size: 16, color: AppColors.success),
                                      label: Text('Connected'),
                                      visualDensity: VisualDensity.compact,
                                    )
                                  : ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: isThisConnecting
                                          ? null
                                          : () => _connectToDevice(device),
                                      child: isThisConnecting
                                          ? const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Connect'),
                                    ),
                            );
                          },
                        ),
                      ],
                    ],
                  ),

                  const Gap(8),

                  // Print Behavior Settings
                  SettingsSectionCard(
                    title: 'Print Preferences',
                    icon: Icons.tune,
                    iconColor: AppColors.secondary,
                    children: [
                      // Paper Width
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Paper Roll Width'),
                        subtitle: const Text('DC Code M21 uses 58mm thermal paper roll'),
                        trailing: DropdownButton<PaperWidth>(
                          value: paperWidth,
                          underline: const SizedBox.shrink(),
                          borderRadius: BorderRadius.circular(12),
                          items: PaperWidth.values.map((pw) {
                            return DropdownMenuItem(
                              value: pw,
                              child: Text(pw.label),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(printerSettingsProvider.notifier).setPaperWidth(val);
                            }
                          },
                        ),
                      ),
                      const Divider(height: 1),

                      // Auto-Print Toggle
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Auto-print After Payment'),
                        subtitle: const Text('Automatically send receipt to printer when payment is confirmed (Default: OFF)'),
                        value: autoPrint,
                        activeThumbColor: AppColors.primary,
                        onChanged: (val) {
                          ref.read(printerSettingsProvider.notifier).setAutoPrint(val);
                        },
                      ),
                      const Divider(height: 1),

                      // Print Copies Count (1 or 2)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Print Copies'),
                        subtitle: const Text('Choose 1 copy (customer) or 2 copies (customer + club)'),
                        trailing: SegmentedButton<int>(
                          segments: const [
                            ButtonSegment(value: 1, label: Text('1 Copy')),
                            ButtonSegment(value: 2, label: Text('2 Copies')),
                          ],
                          selected: {printCopies},
                          onSelectionChanged: (newSelection) {
                            if (newSelection.isNotEmpty) {
                              ref.read(printerSettingsProvider.notifier).setPrintCopies(newSelection.first);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard({
    required ThemeData theme,
    required bool isConnected,
    required String? savedName,
    required String? savedMac,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? AppColors.success : AppColors.warning,
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isConnected ? 'Printer Online' : 'Printer Offline / Disconnected',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isConnected ? AppColors.success : AppColors.warning,
                        ),
                      ),
                      if (savedName != null) ...[
                        const Gap(2),
                        Text(
                          '$savedName (${savedMac ?? ""})',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (isConnected || savedMac != null) ...[
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.receipt_long, size: 18),
                      label: const Text('Test Print'),
                      onPressed: _isTesting ? null : _testPrint,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                      ),
                      icon: const Icon(Icons.link_off, size: 18),
                      label: const Text('Disconnect'),
                      onPressed: _disconnect,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
