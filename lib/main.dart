import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:ble_macos/ble_controller.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});
  @override
  State<MyHomePage> createState() => _MyHomePageState();
  
}

class _MyHomePageState extends State<MyHomePage> {
  BluetoothDevice myDevice = BluetoothDevice(remoteId:DeviceIdentifier(""));
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("BLE SCANNER"),
        ),
        body: GetBuilder<BleController>(
          init: BleController(),
          builder: (BleController controller) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  StreamBuilder<List<ScanResult>>(
                      stream: controller.scanResults,
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Expanded(
                            child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: snapshot.data!.length,
                                itemBuilder: (context, index) {
                                  final data = snapshot.data![index];
                                  myDevice = data.device;
                                  return Card(
                                    elevation: 2,
                                    child: ListTile(
                                      title: Text(data.device.advName),
                                      subtitle: Text(data.device.remoteId.str),
                                      trailing: Text(data.rssi.toString()),
                                      onTap: () => controller
                                          .connectToDevice(data.device),
                                    ),
                                  );
                                }),
                          );
                        } else {
                          return Center(
                            child: Text("No Device Found"),
                          );
                        }
                      }),
                  SizedBox(
                    height: 10,
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                          onPressed: () async {
                            controller.scanDevices();
                            // await controller.disconnectDevice();
                          },
                          child: Text("SCAN")),
                      ElevatedButton(
                          onPressed: () async {
                            controller.toggleLed();
                            // await controller.disconnectDevice();
                          },
                          child: Text("Toggle")),
                      ElevatedButton(
                          onPressed: () async {
                            controller.disconnectDevice(myDevice);
                            // await controller.disconnectDevice();
                          },
                          child: Text("Disconnect")),
                    ],
                  ),
                ],
              ),
            );
          },
        ));
  }
}
