import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';

class ConnectivityPage extends StatefulWidget {
  @override
  _ConnectivityPageState createState() => _ConnectivityPageState();
}

class _ConnectivityPageState extends State<ConnectivityPage> {
  static const platform = MethodChannel('wifi_channel');
  final ssidController = TextEditingController();
  final passwordController = TextEditingController();
  String connectionStatus = 'Not connected';
  String macAddress = 'Unknown'; // Variable to hold MAC address
  bool _obscurePassword = true; // State to toggle password visibility

  Future<void> requestLocationPermission() async {
    var status = await Permission.location.status;

    if (status.isDenied) {
      // Request location permission
      status = await Permission.location.request();
      if (!status.isGranted) {
        // Permission was denied or permanently denied
        print("Location permission is required to connect to Wi-Fi.");
        return;
      }
    }
  }

  Future<void> connectToWifi() async {
    await requestLocationPermission(); // Make sure to await this

    try {
      final String result = await platform.invokeMethod('connectToWifi', {
        'ssid': ssidController.text,
        'password': passwordController.text,
      });

      setState(() {
        connectionStatus = result;
      });
      if (result.contains('Connected to ${ssidController.text}')) {
        Navigator.pushNamed(context, '/login');
      }
    } on PlatformException catch (e) {
      setState(() {
        connectionStatus = "Failed to connect: '${e.message}'";
      });
    }
  }

  Future<void> getAndroidId() async {
    try {
      final String result = await platform.invokeMethod('getAndroidId');
      setState(() {
        macAddress = result; // Set the retrieved Android ID
      });
    } on PlatformException catch (e) {
      print("Failed to get Android ID: '${e.message}'.");
    }
  }

  @override
  void initState() {
    super.initState();
    getAndroidId(); // Call to get MAC address when the page is initialized
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Connect to WiFi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: ssidController,
              decoration: InputDecoration(
                labelText: 'SSID',
                border: OutlineInputBorder(),
              ),
              textInputAction: TextInputAction.next, // Move to next field
              onSubmitted: (_) => FocusScope.of(context).nextFocus(), // On submit, go to next field
            ),
            SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword; // Toggle password visibility
                    });
                  },
                ),
              ),
              obscureText: _obscurePassword, // Toggle visibility based on state
              textInputAction: TextInputAction.done, // Submit action for this field
              onSubmitted: (_) => connectToWifi(), // On submit, try to connect
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: connectToWifi,
              child: Text('Connect to WiFi'),
            ),
            SizedBox(height: 20),
            Text('Connection Status: $connectionStatus'),
            Text('Device MAC Address: $macAddress'), // Display the device MAC address
          ],
        ),
      ),
    );
  }
}
