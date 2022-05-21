// ignore_for_file: lines_longer_than_80_chars

import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:trn_bluetooth_manager/app/permission.dart';

class BluetoothTestPage extends StatefulWidget {
  const BluetoothTestPage({super.key});

  @override
  State<BluetoothTestPage> createState() => _BluetoothTestPageState();
}

class _BluetoothTestPageState extends State<BluetoothTestPage> {
  FlutterBluePlus flutterBluePlus = FlutterBluePlus.instance;

  Future<List<ScanResult>> scan() async {
    final deviceList = <ScanResult>[];

    await flutterBluePlus.startScan(
      timeout: const Duration(seconds: 4),
      scanMode: ScanMode.balanced,
    );

    flutterBluePlus.scanResults.listen((event) {
      for (final r in event) {
        deviceList.add(r);
      }
    });

    await flutterBluePlus.stopScan();

    return deviceList;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: FutureBuilder(
                  future: scan(),
                  builder: (_, AsyncSnapshot<List<ScanResult>> snapshot) {
                    return ListView.builder(
                      itemCount: snapshot.data?.length,
                      itemBuilder: (_, index) {
                        final currentItem = snapshot.data?[index];

                        return SizedBox(
                          width: MediaQuery.of(context).size.width / 1.5,
                          child: Column(
                            children: [
                              Text('ID: ${currentItem?.device.id}'),
                              Text('Name: ${currentItem?.device.name}'),
                              Text('Type: ${currentItem?.device.type}'),
                              Text(
                                'State: ${currentItem?.device.state.listen(inspect)}',
                              ),
                              // Text(
                              //   'Services: ${currentItem?.device.services.listen(inspect)}',
                              // ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                    onPressed: scan,
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
