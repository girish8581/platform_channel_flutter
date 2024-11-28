import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PrinterTestApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: BluetoothPrinterPage(),
    );
  }
}

class BluetoothPrinterPage extends StatefulWidget {
  @override
  _BluetoothPrinterPageState createState() => _BluetoothPrinterPageState();
}

class _BluetoothPrinterPageState extends State<BluetoothPrinterPage> {
  static const platform = MethodChannel('com.example.app/channel');

  List<Map<Object?, Object?>> pairedDevices = [];
  String? selectedDeviceAddress;
  bool isFetchedDevices = false;
  bool isSelected = false;
  late Future<void> pairedDevicesFuture;

  @override
  void initState() {
    super.initState();
    pairedDevicesFuture = fetchPairedDevices(); // Cache the future
  }

  Future<void> fetchPairedDevices() async {
    try {
      // Check if Bluetooth is enabled
      final isEnabled = await isBluetoothEnabled();
      if (!isEnabled) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Bluetooth is not enabled. Please enable it.")),
        );
        return;
      }

      // Fetch paired devices if Bluetooth is enabled
      final List<dynamic> devices = await platform.invokeMethod('getPairedDevices');
      setState(() {
        pairedDevices = devices.cast<Map<Object?, Object?>>();
        isFetchedDevices = true;
      });
    } catch (e) {
      print("Error fetching paired devices: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching paired devices: $e")),
      );
    }
  }


  Future<bool> isBluetoothEnabled() async {
    try {
      final bool isEnabled = await platform.invokeMethod('isBluetoothEnabled');
      return isEnabled;
    } catch (e) {
      print("Error checking Bluetooth status: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error checking Bluetooth status: $e")),
      );
      return false;
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

  Future<void> connectPrinter() async {
    try {
      final result = await platform.invokeMethod('connectPrinter');
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
    try {
      final result = await platform.invokeMethod('printText', {
        'text': '** TEST PRINT OUT **\n',
        'font': 1, // Replace with appropriate constant
        'alignment': 1, // Replace with appropriate constant
      });
      final result1 = await platform.invokeMethod('printText', {
        'text': 'Hello Girish\n',
        'font': 0, // Replace with appropriate constant
        'alignment': 1, // Replace with appropriate constant
      });
      final result2 = await platform.invokeMethod('printText', {
        'text': 'Softland Printer Working \n',
        'font': 0, // Replace with appropriate constant
        'alignment': 2, // Replace with appropriate constant
      });
      final result3 = await platform.invokeMethod('printText', {
        'text': 'Successfully\n',
        'font': 0, // Replace with appropriate constant
        'alignment': 0, // Replace with appropriate constant
      });

      printLineFeed();

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

  Future<void> disconnectPrinter() async {
    try {
      final result = await platform.invokeMethod('disconnectPrinter');
      print(result);

      setState(() {
        isSelected = false;
        selectedDeviceAddress = '';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    } catch (e) {
      print("Error disconnecting from printer: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error disconnecting from printer: $e")),
      );
    }
  }

  Future<void> printLineFeed() async {
    try {
      final result = await platform.invokeMethod('setLineFeed', {
        'lineFeedCount': 3, // Replace with appropriate constant
      });
      print(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    } catch (e) {
      print("Error disconnecting from printer: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error disconnecting from printer: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Bluetooth Printer')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Bluetooth Devices'),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Container(
                decoration: BoxDecoration(color: Colors.greenAccent,border: Border.all()),
                height: 300,
                child: FutureBuilder(
                  future: pairedDevicesFuture, // Use cached future
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
                          final isSelected = selectedDeviceAddress == device['address']?.toString();

                          return ListTile(
                            selected: isSelected,
                            selectedTileColor: Colors.redAccent,
                            title: Text(device['name']?.toString() ?? 'Unknown'),
                            subtitle: Text(device['address']?.toString() ?? 'No Address'),
                            trailing: TextButton(
                              style: ButtonStyle(
                                backgroundColor: WidgetStateProperty.all<Color>(
                                  isSelected ? Colors.redAccent : Colors.grey.shade300,
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  selectedDeviceAddress = device['address']?.toString();
                                });

                                if(!isSelected){
                                  connectToSelectedPrinter(device['address']!.toString());
                                }else{
                                  disconnectPrinter();
                                }

                              },
                              child: Text(
                                isSelected ? 'Tap to Disconnect' : 'Tap to Connect',
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            // onTap: () {
                            //   setState(() {
                            //     selectedDeviceAddress = device['address']?.toString();
                            //   });
                            //   if(!isSelected){
                            //     connectToSelectedPrinter(device['address']!.toString());
                            //   }else{
                            //     disconnectPrinter();
                            //   }
                            // },
                          );
                        },
                      );
                    }
                  },
                ),
              ),
            ),
            ElevatedButton(
              style: ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(Colors.blueAccent)),
              onPressed: fetchPairedDevices,
              child: Text('Fetch Devices',style: TextStyle(color: Colors.white,fontSize: 14, fontWeight: FontWeight.bold),),
            ),
            ElevatedButton(
              style: ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(Colors.blueAccent)),
              onPressed: printSampleText,
              child: Text('Printer Test',style: TextStyle(color: Colors.white,fontSize: 14, fontWeight: FontWeight.bold),),
            ),
            ElevatedButton(
              style: ButtonStyle(backgroundColor: WidgetStateProperty.all<Color>(Colors.blueAccent)),
              onPressed: disconnectPrinter,
              child: Text('Disconnect',style: TextStyle(color: Colors.white,fontSize: 14, fontWeight: FontWeight.bold),),
            ),
          ],
        ),
      ),
    );
  }
}
