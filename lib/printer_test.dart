import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:platform_channel_example_flutter/printer_test_app.dart';


// class PrinterTestApp extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return MaterialApp(
//       home: BluetoothPrinterPage(),
//     );
//   }
// }

class BluetoothPrinterPageNew extends StatefulWidget {
  @override
  _BluetoothPrinterPageNewState createState() => _BluetoothPrinterPageNewState();
}

class _BluetoothPrinterPageNewState extends State<BluetoothPrinterPageNew> {
  Future<void> requestPermissions() async {
    if (await Permission.bluetooth.isDenied ||
        await Permission.bluetoothConnect.isDenied ||
        await Permission.bluetoothScan.isDenied) {
      await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
      ].request();
    }
  }

  @override
  void initState() {
    super.initState();
    requestPermissions();
    fetchPairedDevices();
  }


  static const platform = MethodChannel('com.example.app/channel');
  List<Map<String, String>> pairedDevices = [];
  String? selectedDeviceAddress;

  Future<void> fetchPairedDevices() async {
    try {
      final List<dynamic> devices = await platform.invokeMethod('getPairedDevices');
      setState(() {
        pairedDevices = devices.cast<Map<String, String>>();
      });
    } catch (e) {
      print("Error fetching paired devices: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching paired devices: $e")),
      );
    }
  }

  Future<void> connectToSelectedPrinter(String deviceAddress) async {
    try {
      final result = await platform.invokeMethod('connectToSelectedPrinter', {
        'deviceAddress': deviceAddress,
      });
      print(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    } catch (e) {
      print("Error connecting to printer: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error connecting to printer: $e")),
      );
    }
  }

  Future<void> printSampleText() async {
    if (selectedDeviceAddress == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("No printer connected. Please connect to a printer first.")),
      );
      return;
    }

    try {
      final result = await platform.invokeMethod('printText', {
        'text': '(DUPLICATE COPY)',
        'font': 0, // Replace with appropriate constant
        'alignment': 1, // Replace with appropriate constant
      });
      print(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    } catch (e) {
      print("Error printing: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error printing: $e")),
      );
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth Printer')),
      body: Column(
        children: [
          Expanded(
            child: FutureBuilder(
              future: fetchPairedDevices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error fetching paired devices.'));
                } else if (pairedDevices.isEmpty) {
                  return Center(child: Text('No paired devices found.'));
                } else {
                  print('Paired devices count: ${pairedDevices.length}'); // Print device count

                  return ListView.builder(
                    itemCount: pairedDevices.length,
                    itemBuilder: (context, index) {
                      final device = pairedDevices[index];
                      return ListTile(
                        title: Text(device['name'] ?? 'Unknown'),
                        subtitle: Text(device['address'] ?? 'No Address'),
                        onTap: () {
                          if (pairedDevices.isNotEmpty) {
                            setState(() {
                              selectedDeviceAddress = device['address'];
                            });
                            connectToSelectedPrinter(device['address']!);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('No devices available to select.')),
                            );
                          }
                        },
                      );
                    },
                  );
                }
              },
            ),
          ),
          if (selectedDeviceAddress != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                children: [
                  Text('Selected Printer: $selectedDeviceAddress'),
                  ElevatedButton(
                    onPressed: printSampleText,
                    child: Text('Print Test'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
