import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/services/bluetooth_printer_service.dart';
import 'package:snooker_club/core/services/receipt_formatter.dart';

/// Global singleton instance of BluetoothPrinterService
final bluetoothPrinterServiceProvider = Provider<BluetoothPrinterService>((ref) {
  return BluetoothPrinterService();
});

class PrinterSettingsState {
  final String? savedMac;
  final String? savedName;
  final bool isConnected;
  final bool autoPrint;
  final int printCopies;
  final PaperWidth paperWidth;

  const PrinterSettingsState({
    this.savedMac,
    this.savedName,
    this.isConnected = false,
    this.autoPrint = false,
    this.printCopies = 1,
    this.paperWidth = PaperWidth.mm58,
  });

  PrinterSettingsState copyWith({
    String? savedMac,
    bool clearMac = false,
    String? savedName,
    bool clearName = false,
    bool? isConnected,
    bool? autoPrint,
    int? printCopies,
    PaperWidth? paperWidth,
  }) {
    return PrinterSettingsState(
      savedMac: clearMac ? null : (savedMac ?? this.savedMac),
      savedName: clearName ? null : (savedName ?? this.savedName),
      isConnected: isConnected ?? this.isConnected,
      autoPrint: autoPrint ?? this.autoPrint,
      printCopies: printCopies ?? this.printCopies,
      paperWidth: paperWidth ?? this.paperWidth,
    );
  }
}

final printerSettingsProvider =
    NotifierProvider<PrinterSettingsNotifier, PrinterSettingsState>(
  PrinterSettingsNotifier.new,
);

class PrinterSettingsNotifier extends Notifier<PrinterSettingsState> {
  bool _isConnecting = false;

  @override
  PrinterSettingsState build() {
    final storage = ref.watch(localStorageServiceProvider);
    final mac = storage.getPrinterMac();
    final name = storage.getPrinterName();
    final autoPrint = storage.getAutoPrint();
    final copies = storage.getPrintCopies();
    final paper = storage.getPaperWidth();

    return PrinterSettingsState(
      savedMac: mac,
      savedName: name,
      autoPrint: autoPrint,
      printCopies: (copies == 2) ? 2 : 1,
      paperWidth: paper == '80' ? PaperWidth.mm80 : PaperWidth.mm58,
    );
  }

  /// Silently attempts to auto-reconnect to the saved printer in the background
  Future<bool> autoConnect({bool force = false}) async {
    if (kIsWeb) return false;
    if (_isConnecting) return false;

    final savedMac = state.savedMac;
    final savedName = state.savedName;
    if (savedMac == null) return false;

    final service = ref.read(bluetoothPrinterServiceProvider);

    // If already connected and not forcing, keep state in sync
    if (!force) {
      final isAlreadyConnected = await service.isConnected;
      if (isAlreadyConnected) {
        if (!state.isConnected) {
          setConnected(true);
        }
        return true;
      }
    }

    // Check if Bluetooth is turned on
    final isBtAvailable = await service.isBluetoothAvailable();
    if (!isBtAvailable) {
      if (state.isConnected) setConnected(false);
      return false;
    }

    _isConnecting = true;
    try {
      final success = await service.connectByMac(savedMac, name: savedName);
      setConnected(success);
      return success;
    } catch (e) {
      debugPrint('[PrinterSettingsNotifier] autoConnect error: $e');
      setConnected(false);
      return false;
    } finally {
      _isConnecting = false;
    }
  }

  Future<void> saveConnectedPrinter({required String mac, required String name}) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setPrinterMac(mac);
    await storage.setPrinterName(name);
    state = state.copyWith(savedMac: mac, savedName: name, isConnected: true);
  }

  Future<void> clearSavedPrinter() async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setPrinterMac(null);
    await storage.setPrinterName(null);
    state = state.copyWith(clearMac: true, clearName: true, isConnected: false);
    await ref.read(bluetoothPrinterServiceProvider).disconnect();
  }

  void setConnected(bool connected) {
    state = state.copyWith(isConnected: connected);
  }

  Future<void> setAutoPrint(bool value) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setAutoPrint(value);
    state = state.copyWith(autoPrint: value);
  }

  Future<void> setPrintCopies(int value) async {
    final safe = (value == 2) ? 2 : 1;
    final storage = ref.read(localStorageServiceProvider);
    await storage.setPrintCopies(safe);
    state = state.copyWith(printCopies: safe);
  }

  Future<void> setPaperWidth(PaperWidth width) async {
    final storage = ref.read(localStorageServiceProvider);
    await storage.setPaperWidth(width == PaperWidth.mm80 ? '80' : '58');
    state = state.copyWith(paperWidth: width);
  }
}
