// For performing some operations asynchronously
import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';

// For using PlatformException
import 'package:flutter/services.dart';

import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class BluetoothApp extends StatefulWidget {
  const BluetoothApp({super.key});

  @override
  State<BluetoothApp> createState() => _BluetoothAppState();
}

class _BluetoothAppState extends State<BluetoothApp> {
  // Initializing the Bluetooth connection state to be unknown
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  // Initializing a global key, as it would help us in showing a SnackBar later
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Get the instance of the Bluetooth
  final FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  // Track the Bluetooth connection with the remote device
  BluetoothConnection? connection;

  int? _deviceState;

  bool isDisconnecting = false;

  Map<String, Color> colors = {
    'onBorderColor': Colors.green,
    'offBorderColor': Colors.red,
    'neutralBorderColor': Colors.transparent,
    'onTextColor': Colors.green[700]!,
    'offTextColor': Colors.red[700]!,
    'neutralTextColor': Colors.blue,
  };

  // To track whether the device is still connected to Bluetooth
  bool get isConnected => connection != null && connection!.isConnected;

  // Define some variables, which will be required later
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _device;
  bool _connected = false;
  bool _isButtonUnavailable = false;

  @override
  void initState() {
    super.initState();

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _deviceState = 0; // neutral

    // If the bluetooth of the device is not enabled,
    // then request permission to turn on bluetooth
    // as the app starts up
    enableBluetooth();

    // Listen for further state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
        if (_bluetoothState == BluetoothState.STATE_OFF) {
          _isButtonUnavailable = true;
        }
        getPairedDevices();
      });
    });
  }

  @override
  void dispose() {
    // Avoid memory leak and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection?.dispose();
      connection = null;
    }

    super.dispose();
  }

  // Request Bluetooth permission from the user
  Future<bool> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    // If the bluetooth is off, then turn it on first
    // and then retrieve the devices that are paired.
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  // For retrieving and storing the paired devices
  // in a list.
  Future<void> getPairedDevices() async {
    var devices = <BluetoothDevice>[];

    // To get the list of paired devices
    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      debugPrint('Error');
    }

    // It is an error to call [setState] unless [mounted] is true.
    if (!mounted) {
      return;
    }

    // Store the [devices] list in the [_devicesList] for accessing
    // the list outside this class
    setState(() {
      _devicesList = devices;
    });
  }

  // Now, its time to build the UI
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          title: const Text('Flutter Bluetooth'),
          backgroundColor: Colors.deepPurple,
          actions: <Widget>[
            FlatButton.icon(
              icon: const Icon(
                Icons.refresh,
                color: Colors.white,
              ),
              label: const Text(
                'Refresh',
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              splashColor: Colors.deepPurple,
              onPressed: () async {
                // So, that when new devices are paired
                // while the app is running, user can refresh
                // the paired devices list.
                await getPairedDevices().then((_) {
                  show('Device list refreshed');
                });
              },
            ),
          ],
        ),
        body: Column(
          children: <Widget>[
            Visibility(
              visible: _isButtonUnavailable &&
                  _bluetoothState == BluetoothState.STATE_ON,
              child: const LinearProgressIndicator(
                backgroundColor: Colors.yellow,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: <Widget>[
                  const Expanded(
                    child: Text(
                      'Enable Bluetooth',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Switch(
                    value: _bluetoothState.isEnabled,
                    onChanged: (bool value) {
                      Future<void> future() async {
                        if (value) {
                          await FlutterBluetoothSerial.instance.requestEnable();
                        } else {
                          await FlutterBluetoothSerial.instance
                              .requestDisable();
                        }

                        await getPairedDevices();
                        _isButtonUnavailable = false;

                        if (_connected) {
                          unawaited(_disconnect());
                        }
                      }

                      future().then((_) {
                        setState(() {});
                      });
                    },
                  )
                ],
              ),
            ),
            Stack(
              children: <Widget>[
                Column(
                  children: <Widget>[
                    const Padding(
                      padding: EdgeInsets.only(top: 10),
                      child: Text(
                        'PAIRED DEVICES',
                        style: TextStyle(fontSize: 24, color: Colors.blue),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          const Text(
                            'Device:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          DropdownButton(
                            items: _getDeviceItems(),
                            onChanged: (BluetoothDevice? value) =>
                                setState(() => _device = value),
                            value: _devicesList.isNotEmpty ? _device : null,
                          ),
                          RaisedButton(
                            onPressed: _isButtonUnavailable
                                ? null
                                : _connected
                                    ? _disconnect
                                    : _connect,
                            child: Text(_connected ? 'Disconnect' : 'Connect'),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          side: BorderSide(
                            color: _deviceState == 0
                                ? colors['neutralBorderColor']!
                                : _deviceState == 1
                                    ? colors['onBorderColor']!
                                    : colors['offBorderColor']!,
                            width: 3,
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        elevation: _deviceState == 0 ? 4 : 0,
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                child: Text(
                                  'DEVICE 1',
                                  style: TextStyle(
                                    fontSize: 20,
                                    color: _deviceState == 0
                                        ? colors['neutralTextColor']
                                        : _deviceState == 1
                                            ? colors['onTextColor']
                                            : colors['offTextColor'],
                                  ),
                                ),
                              ),
                              FlatButton(
                                onPressed: _connected
                                    ? _sendOnMessageToBluetooth
                                    : null,
                                child: const Text('ON'),
                              ),
                              FlatButton(
                                onPressed: _connected
                                    ? _sendOffMessageToBluetooth
                                    : null,
                                child: const Text('OFF'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const ColoredBox(
                  color: Colors.blue,
                ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      const Text(
                        'NOTE: If you cannot find the device in the list, please pair the device by going to the bluetooth settings',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                      const SizedBox(height: 15),
                      RaisedButton(
                        elevation: 2,
                        child: const Text('Bluetooth Settings'),
                        onPressed: () {
                          FlutterBluetoothSerial.instance.openSettings();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // Create the List of devices to be shown in Dropdown Menu
  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    final items = <DropdownMenuItem<BluetoothDevice>>[];
    if (_devicesList.isEmpty) {
      items.add(
        const DropdownMenuItem(
          child: Text('NONE'),
        ),
      );
    } else {
      for (final device in _devicesList) {
        items.add(
          DropdownMenuItem(
            value: device,
            child: Text(device.name!),
          ),
        );
      }
    }
    return items;
  }

  // Method to connect to bluetooth
  Future<void> _connect() async {
    setState(() {
      _isButtonUnavailable = true;
    });
    if (_device == null) {
      await show('No device selected');
    } else {
      if (!isConnected) {
        await BluetoothConnection.toAddress(_device?.address)
            .then((_connection) {
          debugPrint('Connected to the device');
          connection = _connection;
          setState(() {
            _connected = true;
          });

          connection!.input!.listen(null).onDone(() {
            if (isDisconnecting) {
              debugPrint('Disconnecting locally!');
            } else {
              debugPrint('Disconnected remotely!');
            }
            if (mounted) {
              setState(() {});
            }
          });
        }).catchError((Object error) {
          debugPrint('Cannot connect, exception occurred');
          debugPrint('$error');
        });
        await show('Device connected');

        setState(() => _isButtonUnavailable = false);
      }
    }
  }

  // void _onDataReceived(Uint8List data) {
  //   // Allocate buffer for parsed data
  //   int backspacesCounter = 0;
  //   data.forEach((byte) {
  //     if (byte == 8 || byte == 127) {
  //       backspacesCounter++;
  //     }
  //   });
  //   Uint8List buffer = Uint8List(data.length - backspacesCounter);
  //   int bufferIndex = buffer.length;

  //   // Apply backspace control character
  //   backspacesCounter = 0;
  //   for (int i = data.length - 1; i >= 0; i--) {
  //     if (data[i] == 8 || data[i] == 127) {
  //       backspacesCounter++;
  //     } else {
  //       if (backspacesCounter > 0) {
  //         backspacesCounter--;
  //       } else {
  //         buffer[--bufferIndex] = data[i];
  //       }
  //     }
  //   }
  // }

  // Method to disconnect bluetooth
  Future<void> _disconnect() async {
    setState(() {
      _isButtonUnavailable = true;
      _deviceState = 0;
    });

    await connection?.close();
    await show('Device disconnected');
    if (!connection!.isConnected) {
      setState(() {
        _connected = false;
        _isButtonUnavailable = false;
      });
    }
  }

  // Method to send message,
  // for turning the Bluetooth device on
  Future<void> _sendOnMessageToBluetooth() async {
    connection?.output.add(utf8.encode('1' '\r\n') as Uint8List);
    await connection?.output.allSent;
    await show('Device Turned On');
    setState(() {
      _deviceState = 1; // device on
    });
  }

  // Method to send message,
  // for turning the Bluetooth device off
  Future<void> _sendOffMessageToBluetooth() async {
    connection?.output.add(utf8.encode('0' '\r\n') as Uint8List);
    await connection?.output.allSent;
    await show('Device Turned Off');
    setState(() {
      _deviceState = -1; // device off
    });
  }

  // Method to show a Snackbar,
  // taking message as the text
  Future show(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _scaffoldKey.currentState?.showSnackBar(
      SnackBar(
        content: Text(
          message,
        ),
        duration: duration,
      ),
    );
  }
}
