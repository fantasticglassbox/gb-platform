import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:glassbox/pages/login.dart';

class WifiSetupPage extends StatefulWidget {
  @override
  _WifiSetupPageState createState() => _WifiSetupPageState();
}

class _WifiSetupPageState extends State<WifiSetupPage> {
  final TextEditingController _ssidController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  static const platform = MethodChannel('wifi_channel');

  Future<void> _connectToWifi() async {
    try {
      final String result = await platform.invokeMethod('connectToWifi', {
        'ssid': _ssidController.text,
        'password': _passwordController.text,
      });
      print(result); // You can show a confirmation or error to the user
      // Navigate to the LoginPage after successful connection
      if (result == "Connected to Wi-Fi") {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } on PlatformException catch (e) {
      print("Failed to connect to Wi-Fi: '${e.message}'.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wi-Fi Setup'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _ssidController,
              decoration: InputDecoration(labelText: 'SSID'),
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _connectToWifi,
              child: Text('Connect'),
            ),
          ],
        ),
      ),
    );
  }
}
