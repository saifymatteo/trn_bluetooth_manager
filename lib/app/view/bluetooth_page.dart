import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  // Initialize bluetooth connection state to UNKNOWN
  BluetoothState bluetoothState = BluetoothState.UNKNOWN;
  // Initialize bluetooth instance
  final FlutterBluetoothSerial bluetooth = FlutterBluetoothSerial.instance;
  // Track bluetooth connection
  BluetoothConnection? connection;

  // Variables
  int? deviceState; // deviceState [1, -1]
  bool isDisconnecting = false;
  List<BluetoothDevice> deviceList = [];
  BluetoothDevice? device;
  bool connected = false;
  bool isButtonUnavailable = false;

  // Track whether device connected to bluetooth
  bool get isConnected => connection != null && connection!.isConnected;

  @override
  void initState() {
    // Get current state
    FlutterBluetoothSerial.instance.state.then(
      (state) => setState(() => bluetoothState = state),
    );
    deviceState = 0; // Set to neutral

    // Request permission as the app start
    enableBluetooth();

    FlutterBluetoothSerial.instance.onStateChanged().listen((state) {
      bluetoothState = state;
      if (bluetoothState == BluetoothState.STATE_OFF) {
        isButtonUnavailable = true;
      }
      getPairedDevices();
    });

    super.initState();
  }

  @override
  void dispose() {
    // Need to properly dispose
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  Future<bool> enableBluetooth() async {
    // Retrieve current Bluetooth state
    bluetoothState = await FlutterBluetoothSerial.instance.state;

    // If bluetooth off, turn it on and then retrieve devices
    if (bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  // Method to retrieve and store paired devices to a list
  Future<void> getPairedDevices() async {
    var devices = <BluetoothDevice>[];

    // Try and get the list of paired devices
    try {
      devices = await bluetooth.getBondedDevices();
    } on PlatformException {
      debugPrint('Error Platform Exception');
    }

    // For [setState] below
    if (!mounted) return;

    // Store the list
    setState(() => deviceList = devices);
  }

  // Method to connect to bluetooth
  Future<void> connect() async {
    setState(() {
      isButtonUnavailable = true;
    });

    if (device == null) {
      show('No device selected');
    } else {
      if (!isConnected) {
        await BluetoothConnection.toAddress(device?.address).then((value) {
          show('Connected to the device');
          connection = value;
          setState(() {
            connected = true;
          });

          connection?.input!.listen(null).onDone(() {
            if (isDisconnecting) {
              show('Disconnecting locally!');
            } else {
              show('Disconnected remotely');
            }
            if (mounted) {
              setState(() {});
            }
          });
        }).catchError((Object error) {
          show('Error: $error');
        });

        show('Device connected');

        setState(() => isButtonUnavailable = false);
      }
    }
  }

  // Method to disconnect from bluetooth
  Future<void> disconnect() async {
    setState(() {
      isButtonUnavailable = true;
      deviceState = 0;
    });

    await connection?.close();
    show('Device disconnected');
    if (!connection!.isConnected) {
      setState(() {
        connected = false;
        isButtonUnavailable = false;
      });
    }
  }

  // Create the List of devices to be shown in Dropdown Menu
  List<DropdownMenuItem<BluetoothDevice>> getDeviceItems() {
    final items = <DropdownMenuItem<BluetoothDevice>>[];
    if (deviceList.isEmpty) {
      items.add(const DropdownMenuItem(
        child: Text('NONE'),
      ),);
    } else {
      for (final device in deviceList) {
        items.add(DropdownMenuItem(
          value: device,
          child: Text(device.name!),
        ),);
      }
    }
    return items;
  }

  // Method to show Snackbar
  SnackBar show(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    Future<void>.delayed(const Duration(milliseconds: 100));
    return SnackBar(content: Text(message), duration: duration);
  }

  Future<void> bluetoothOnOffSwitch({bool? condition}) async {
    if (condition!) {
      await FlutterBluetoothSerial.instance.requestEnable();
    } else {
      await FlutterBluetoothSerial.instance.requestDisable();
    }

    await getPairedDevices();
    isButtonUnavailable = false;

    if (connected) {
      await disconnect();
    }
  }

  // UI parts
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Visibility(
              visible: isButtonUnavailable &&
                  bluetoothState == BluetoothState.STATE_ON,
              child: const LinearProgressIndicator(
                backgroundColor: Colors.yellow,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Enable Bluetooth'),
                  Switch(
                    value: bluetoothState.isEnabled,
                    onChanged: (value) async {
                      await bluetoothOnOffSwitch(condition: value).then((_) {
                        setState(() {});

                        if (value) {
                          ScaffoldMessenger.of(context)
                            // ignore: unnecessary_statements
                            ..hideCurrentMaterialBanner
                            ..showSnackBar(show('Bluetooth On!'));
                        } else {
                          ScaffoldMessenger.of(context)
                            // ignore: unnecessary_statements
                            ..hideCurrentMaterialBanner
                            ..showSnackBar(show('Bluetooth Off!'));
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            const Text(
              'PAIRED DEVICES',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 30),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: deviceList.length,
                itemBuilder: (_, index) {
                  final item = deviceList[index];
                  return SizedBox(
                    width: MediaQuery.of(context).size.width,
                    child: Row(
                      children: [
                        Text(item.name!),
                      ],
                    ),
                  );
                },
              ),
            ),
            TextButton(
              onPressed: () async {
                await getPairedDevices().then((value) {
                  ScaffoldMessenger.of(context)
                    // ignore: unnecessary_statements
                    ..hideCurrentMaterialBanner
                    ..showSnackBar(show('Refreshed List'));
                });
                setState(() {});
              },
              child: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }
}
