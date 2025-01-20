import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

class BleController extends GetxController {
  Future<void> setUpDevice() async {
// first, check if bluetooth is supported by your hardware
// Note: The platform is initialized on the first call to any FlutterBluePlus method.
    if (await FlutterBluePlus.isSupported == false) {
      if (kDebugMode) {
        print("Bluetooth not supported by this device");
      }
      return;
    }

// handle bluetooth on & off
// note: for iOS the initial state is typically BluetoothAdapterState.unknown
// note: if you have permissions issues you will get stuck at BluetoothAdapterState.unauthorized
    var subscription =
        FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      if (kDebugMode) {
        print(state);
      }
      if (state == BluetoothAdapterState.on) {
        // usually start scanning, connecting, etc
      } else {
        // show an error to the user, etc
      }
    });

// turn on bluetooth ourself if we can
// for iOS, the user controls bluetooth enable/disable
    if (defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS) {
      await FlutterBluePlus.turnOn();
    }

// cancel to prevent duplicate listeners
    subscription.cancel();
  }

  Future<void> scanDevices() async {
// listen to scan results
// Note: `onScanResults` clears the results between scans. You should use
//  `scanResults` if you want the current scan results *or* the results from the previous scan.
    var subscription = FlutterBluePlus.onScanResults.listen(
      (results) {
        if (results.isNotEmpty) {
          ScanResult r = results.last; // the most recently found device
          if (kDebugMode) {
            print(
                '${r.device.remoteId}: "${r.advertisementData.advName}" found!');
          }
        }
      },
      // ignore: avoid_print
      onError: (e) => print(e),
    );

// cleanup: cancel subscription when scanning stops
    FlutterBluePlus.cancelWhenScanComplete(subscription);

// Wait for Bluetooth enabled & permission granted
// In your real app you should use `FlutterBluePlus.adapterState.listen` to handle all states
    await FlutterBluePlus.adapterState
        .where((val) => val == BluetoothAdapterState.on)
        .first;

// Start scanning w/ timeout
// Optional: use `stopScan()` as an alternative to timeout
    await FlutterBluePlus.startScan(
        withNames: ["Ars_Camper"], // *or* any of the specified names
        timeout: Duration(seconds: 15));

// wait for scanning to stop
    await FlutterBluePlus.isScanning.where((val) => val == false).first;
  }

  // Expose scan results as a stream
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;

  // Connect to a BLE device
  Future<void> connectToDevice2(BluetoothDevice device) async {
    try {
      await device.connect();
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.connected) {
          if (kDebugMode) {
            print("Connected to device: ${device.advName}");
          }
        } else if (state == BluetoothConnectionState.disconnected) {
          if (kDebugMode) {
            print("Disconnected from device: ${device.advName}");
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print("Error connecting to device: $e");
      }
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
// listen for disconnection
    var subscription =
        device.connectionState.listen((BluetoothConnectionState state) async {
      if (state == BluetoothConnectionState.disconnected) {
        // 1. typically, start a periodic timer that tries to
        //    reconnect, or just call connect() again right now
        // 2. you must always re-discover services after disconnection!
        if (kDebugMode) {
          print(
              "${device.disconnectReason?.code} ${device.disconnectReason?.description}");
        }
      }
    });

// cleanup: cancel subscription when disconnected
//   - [delayed] This option is only meant for `connectionState` subscriptions.
//     When `true`, we cancel after a small delay. This ensures the `connectionState`
//     listener receives the `disconnected` event.
//   - [next] if true, the the stream will be canceled only on the *next* disconnection,
//     not the current disconnection. This is useful if you setup your subscriptions
//     before you connect.
    device.cancelWhenDisconnected(subscription, delayed: true, next: true);

// Connect to the device
    await device.connect();

// Discover the services of the device
    discoverServices(device);

// cancel to prevent duplicate listeners
    subscription.cancel();
  }

  Future<void> disconnectDevice(BluetoothDevice device) async {
// Disconnect from device
    await device.disconnect();
  }

  Future<void> discoverServices(BluetoothDevice device) async {
// Note: You must call discoverServices after every re-connection!
    List<BluetoothService> services = await device.discoverServices();
    for (var service in services) {
      if (kDebugMode) {
        print("Disconnected from device: ${service.serviceUuid}");
        await readCharacteristic(service);
      }
    }
  }

  Future<void> readCharacteristic(BluetoothService service) async {
    for (BluetoothCharacteristic c in service.characteristics) {
      if (c.properties.read) {
        List<int> value = await c.read();
        if (kDebugMode) {
          print("Device ID: ${c.device.remoteId}");
          print("Service UUID: ${c.serviceUuid}");
          print("Char UUID: ${c.characteristicUuid}");
          print(value);
        }
      }
    }
  }

  Future<void> toggleLed() async {
    Guid myCuuid = Guid("00001525-1212-efde-1523-785feabcd123");
    Guid mySuuid = Guid("00001523-1212-efde-1523-785feabcd123");
    DeviceIdentifier myDid =
        DeviceIdentifier("5DA034FB-79E5-0013-CEDC-38C49BE51467");

    try {
      BluetoothCharacteristic characteristic = BluetoothCharacteristic(
          remoteId: myDid, serviceUuid: mySuuid, characteristicUuid: myCuuid);
      List<int> value = await characteristic.read();
      if (value[0] == 0) {
        await characteristic.write([0x01]);
      } else {
        await characteristic.write([0x00]);
      }
    } catch (e) {
      if (kDebugMode) {
        print("Error connecting to device: $e");
      }
    }
  }
}
