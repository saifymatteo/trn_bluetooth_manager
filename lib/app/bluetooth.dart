

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class BluetoothModule {
  FlutterBluePlus flutterBlue = FlutterBluePlus.instance;
  bool isConnected = false;
  List<ScanResult> deviceList = [];
  List<BluetoothService> deviceServices = [];

  void scan() {
    // Start scan
    flutterBlue.startScan(timeout: const Duration(seconds: 4));

    // Listen to scan result
    flutterBlue.scanResults.listen((event) {
      for (final r in event) {
        deviceList.add(r);
      }
    });

    // Stop scan
    flutterBlue.stopScan();
  }

  Future<void> connect(BluetoothDevice device) async {
    await device.connect();
  }

  void disconnect(BluetoothDevice device) {
    device.disconnect();
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    deviceServices = await device.discoverServices();
  }
}
