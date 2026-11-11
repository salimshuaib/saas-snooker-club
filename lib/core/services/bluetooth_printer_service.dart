import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';

enum PrinterConnectionState { disconnected, connecting, connected, error }

class BluetoothPrinterService {
  static final BluetoothPrinterService _instance = BluetoothPrinterService._internal();
  factory BluetoothPrinterService() => _instance;
  BluetoothPrinterService._internal();

  BluetoothInfo? _connectedPrinter;
  PrinterConnectionState _state = PrinterConnectionState.disconnected;

  BluetoothInfo? get connectedPrinter => _connectedPrinter;
  PrinterConnectionState get state => _state;

  /// Check if Bluetooth is available and enabled on this device
  Future<bool> isBluetoothAvailable() async {
    if (kIsWeb) return false;
    try {
      final isEnabled = await PrintBluetoothThermal.bluetoothEnabled;
      return isEnabled;
    } catch (e) {
      debugPrint('[BluetoothPrinter] isBluetoothAvailable error: $e');
      return false;
    }
  }

  /// Request runtime permissions on Android
  Future<bool> requestPermissions() async {
    if (kIsWeb) return false;
    try {
      final hasPerm = await PrintBluetoothThermal.isPermissionBluetoothGranted;
      if (hasPerm) return true;

      // Request via permission_handler
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      final allGranted = statuses.values.any((s) => s.isGranted);
      return allGranted;
    } catch (e) {
      debugPrint('[BluetoothPrinter] requestPermissions error: $e');
      return false;
    }
  }

  /// Get list of paired Bluetooth devices
  Future<List<BluetoothInfo>> getPairedDevices() async {
    if (kIsWeb) return [];
    try {
      final isEnabled = await isBluetoothAvailable();
      if (!isEnabled) return [];

      await requestPermissions();
      final List<BluetoothInfo> devices = await PrintBluetoothThermal.pairedBluetooths;
      return devices;
    } catch (e) {
      debugPrint('[BluetoothPrinter] getPairedDevices error: $e');
      return [];
    }
  }

  /// Check current connection status
  Future<bool> get isConnected async {
    if (kIsWeb) return false;
    try {
      final connected = await PrintBluetoothThermal.connectionStatus;
      if (!connected) {
        _state = PrinterConnectionState.disconnected;
      }
      return connected;
    } catch (e) {
      debugPrint('[BluetoothPrinter] connectionStatus error: $e');
      return false;
    }
  }

  /// Connect to a specific printer by BluetoothInfo
  Future<bool> connect(BluetoothInfo device) async {
    if (kIsWeb) return false;
    try {
      _state = PrinterConnectionState.connecting;
      final bool result = await PrintBluetoothThermal.connect(
        macPrinterAddress: device.macAdress,
      );
      if (result) {
        _connectedPrinter = device;
        _state = PrinterConnectionState.connected;
        debugPrint('[BluetoothPrinter] Connected to ${device.name} (${device.macAdress})');
      } else {
        _state = PrinterConnectionState.error;
        debugPrint('[BluetoothPrinter] Failed to connect to ${device.name}');
      }
      return result;
    } catch (e) {
      debugPrint('[BluetoothPrinter] connect error: $e');
      _state = PrinterConnectionState.error;
      return false;
    }
  }

  /// Connect directly by MAC address (for auto-reconnect)
  Future<bool> connectByMac(
    String macAddress, {
    String? name,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    if (kIsWeb) return false;
    try {
      _state = PrinterConnectionState.connecting;
      final bool result = await PrintBluetoothThermal.connect(
        macPrinterAddress: macAddress,
      ).timeout(
        timeout,
        onTimeout: () {
          debugPrint('[BluetoothPrinter] Connection to MAC $macAddress timed out');
          return false;
        },
      );
      if (result) {
        _connectedPrinter = BluetoothInfo(
          name: name ?? 'Thermal Printer',
          macAdress: macAddress,
        );
        _state = PrinterConnectionState.connected;
        debugPrint('[BluetoothPrinter] Connected to MAC $macAddress');
      } else {
        _state = PrinterConnectionState.disconnected;
      }
      return result;
    } catch (e) {
      debugPrint('[BluetoothPrinter] connectByMac error: $e');
      _state = PrinterConnectionState.disconnected;
      return false;
    }
  }

  /// Disconnect current printer
  Future<bool> disconnect() async {
    if (kIsWeb) return true;
    try {
      final res = await PrintBluetoothThermal.disconnect;
      _connectedPrinter = null;
      _state = PrinterConnectionState.disconnected;
      return res;
    } catch (e) {
      debugPrint('[BluetoothPrinter] disconnect error: $e');
      return false;
    }
  }

  /// Send raw bytes to printer
  Future<bool> printBytes(List<int> bytes) async {
    if (kIsWeb) return false;
    try {
      final connected = await isConnected;
      if (!connected) {
        // If we have a saved connected printer, attempt reconnect once
        if (_connectedPrinter != null) {
          final reconnected = await connect(_connectedPrinter!);
          if (!reconnected) return false;
        } else {
          return false;
        }
      }
      final bool result = await PrintBluetoothThermal.writeBytes(bytes);
      return result;
    } catch (e) {
      debugPrint('[BluetoothPrinter] printBytes error: $e');
      return false;
    }
  }
}
