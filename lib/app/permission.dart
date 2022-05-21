import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

Future<void> getPermission() async {
  final statusBlue = await Permission.bluetooth.request();
  final statusConnect = await Permission.bluetoothConnect.request();
  final statusScan = await Permission.bluetoothScan.request();
  final statusAdvert = await Permission.bluetoothAdvertise.request();

  if (statusBlue == PermissionStatus.granted) {
    debugPrint('Bluetooth: Permission granted');
  } else if (statusBlue == PermissionStatus.denied) {
    debugPrint('Bluetooth: Permission denied');
  } else if (statusBlue == PermissionStatus.permanentlyDenied) {
    debugPrint('Bluetooth: Prompt user to Setting');
    await openAppSettings();
  }

  if (statusConnect == PermissionStatus.granted) {
    debugPrint('Bluetooth Connect: Permission granted');
  } else if (statusConnect == PermissionStatus.denied) {
    debugPrint('Bluetooth Connect: Permission denied');
  } else if (statusConnect == PermissionStatus.permanentlyDenied) {
    debugPrint('Bluetooth Connect: Prompt user to Setting');
    await openAppSettings();
  }

  if (statusScan == PermissionStatus.granted) {
    debugPrint('Bluetooth Scan: Permission granted');
  } else if (statusScan == PermissionStatus.denied) {
    debugPrint('Bluetooth Scan: Permission denied');
  } else if (statusScan == PermissionStatus.permanentlyDenied) {
    debugPrint('Bluetooth Scan: Prompt user to Setting');
    await openAppSettings();
  }

  if (statusAdvert == PermissionStatus.granted) {
    debugPrint('Bluetooth Advertise: Permission granted');
  } else if (statusAdvert == PermissionStatus.denied) {
    debugPrint('Bluetooth Advertise: Permission denied');
  } else if (statusAdvert == PermissionStatus.permanentlyDenied) {
    debugPrint('Bluetooth Advertise: Prompt user to Setting');
    await openAppSettings();
  }
}
