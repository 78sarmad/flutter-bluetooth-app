import 'dart:async';

import 'package:beacon_broadcast/beacon_broadcast.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'BLE Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: MyHomePage(title: 'Flutter BLE by Sarmad'),
      );
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;
  FlutterBlue flutterBlue = FlutterBlue.instance;
  final List<BluetoothDevice> devicesList = new List<BluetoothDevice>();

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  _addBTDeviceToList(final BluetoothDevice device) {
    if (!widget.devicesList.contains(device)) {
      setState(() {
        widget.devicesList.add(device);
      });
    }
  }

  void _scanDevices() {
    widget.flutterBlue.connectedDevices
        .asStream()
        .listen((List<BluetoothDevice> devices) {
      for (BluetoothDevice device in devices) {
        _addBTDeviceToList(device);
      }
    });
    widget.flutterBlue.scanResults.listen((List<ScanResult> results) {
      for (ScanResult result in results) {
        _addBTDeviceToList(result.device);
      }
    });
    widget.flutterBlue.startScan();
  }

  static const String uuid = '39ED98FF-2900-441A-802F-9C398FC199D2';
  static const int majorId = 1;
  static const int minorId = 100;
  static const int transmissionPower = -59;
  static const AdvertiseMode advertiseMode = AdvertiseMode.lowPower;
  BeaconBroadcast beaconBroadcast = BeaconBroadcast();

  void _startBroadcast() {
    beaconBroadcast
        .setUUID(uuid)
        .setMajorId(majorId)
        .setMinorId(minorId)
        .setTransmissionPower(transmissionPower)
        .setAdvertiseMode(advertiseMode)
        .start();
  }

  BeaconStatus _isTransmissionSupported;
  bool _isAdvertising = false;
  StreamSubscription<bool> _isAdvertisingSubscription;

  @override
  void initState() {
    super.initState();
    _scanDevices();

    beaconBroadcast
        .checkTransmissionSupported()
        .then((isTransmissionSupported) {
      setState(() {
        _isTransmissionSupported = isTransmissionSupported;
      });
    });

    _isAdvertisingSubscription =
        beaconBroadcast.getAdvertisingStateChange().listen((isAdvertising) {
      setState(() {
        _isAdvertising = isAdvertising;
      });
    });
  }

  Future<void> _showBroadcastInfo() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Broadcast Info'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                Text('UUID: $uuid'),
                Text('Major id: $majorId'),
                Text('Minor id: $minorId'),
                Text('Tx Power: $transmissionPower'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Approve'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: Text(widget.title),
        ),
        body: Stack(
          children: [
            Container(
              child: _buildListViewOfDevices(),
            ),
            Positioned(
              left: 20.0,
              bottom: 20.0,
              child: FlatButton(
                onPressed: () {},
                child: Text("Advertising Status: $_isAdvertising"),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FlatButton(
                onPressed: _startBroadcast, child: Text("Start Broadcast")),
            FlatButton(
              onPressed: () => showDialog<String>(
                context: context,
                builder: (BuildContext context) => AlertDialog(
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.pop(context, 'OK'),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ),
              child: Text("Show Broadcast Info"),
            ),
          ],
        ),
      );

  ListView _buildListViewOfDevices() {
    List<Container> containers = new List<Container>();
    for (BluetoothDevice device in widget.devicesList) {
      containers.add(
        Container(
          height: 50,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  children: <Widget>[
                    Text(device.name == '' ? 'UNKNOWN VENDOR' : device.name),
                    Text(device.id.toString()),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(8),
      children: <Widget>[
        ...containers,
      ],
    );
  }
}
