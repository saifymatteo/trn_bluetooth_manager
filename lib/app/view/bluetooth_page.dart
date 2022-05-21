// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:trn_bluetooth_manager/app/bluetooth.dart';
import 'package:trn_bluetooth_manager/app/permission.dart';

class BluetoothPage extends StatefulWidget {
  const BluetoothPage({super.key});

  @override
  State<BluetoothPage> createState() => _BluetoothPageState();
}

class _BluetoothPageState extends State<BluetoothPage> {
  final BluetoothModule bluetoothModule = BluetoothModule();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: bluetoothModule.deviceList.length,
                  itemBuilder: (_, index) {
                    final currentItem = bluetoothModule.deviceList[index];

                    if (currentItem.device.type ==
                        BluetoothDeviceType.unknown) {
                      return const Visibility(
                        visible: false,
                        child: SizedBox(),
                      );
                    } else {
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (bluetoothModule.isConnected) {
                              currentItem.device.disconnect();
                              bluetoothModule.isConnected = false;
                            } else {
                              currentItem.device.connect();
                              bluetoothModule.isConnected = true;
                            }
                          });
                        },
                        child: Container(
                          width: MediaQuery.of(context).size.width / 1.5,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: bluetoothModule.isConnected
                                ? Colors.blue
                                : Colors.grey,
                          ),
                          child: Column(
                            children: [
                              Text('ID: ${currentItem.device.id.toString()}'),
                              Text('Name: ${currentItem.device.name}'),
                              Text(
                                'Type: ${currentItem.device.type.toString()}',
                              ),
                              Text(
                                'canSendWriteWithoutResponse: ${currentItem.device.canSendWriteWithoutResponse}',
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                  },
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: bluetoothModule.deviceServices.length,
                  itemBuilder: (_, index) {
                    final currentItem = bluetoothModule.deviceServices[index];

                    return Container(
                      height: 50,
                      width: MediaQuery.of(context).size.width / 1.5,
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        children: [
                          Text('Device ID: ${currentItem.deviceId}'),
                          Text('Is Primary?: ${currentItem.isPrimary}'),
                          Text('UUID: ${currentItem.uuid}'),
                          Text('Characteristic: ${currentItem.characteristics}'),
                          Text(
                            'IncludedServices: ${currentItem..includedServices}',
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {
                      setState(bluetoothModule.scan);
                    },
                    child: const Text('Start Scan'),
                  ),
                  const TextButton(
                    onPressed: getPermission,
                    child: Text('Get Permission'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
