import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart'; // Import Cache Manager
import 'package:glassbox/manager/cache_manager.dart';
import 'package:permission_handler/permission_handler.dart';

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

  @override
  void initState() {
    super.initState();
    getAndroidId(); // Call to get MAC address when the page is initialized
    checkWifiConnection();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Connectivity'),
        automaticallyImplyLeading: false, // Remove the back button
      ),
      body: Center( // Center the content
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, // Center the buttons vertically
            children: [
              ElevatedButton(
                onPressed: connectToWifi,
                child: Text('Connect to WiFi'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: openDeveloperSetting, // Open developer settings
                child: Text('Open System Setting'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: startGlassbox, // Start Glassbox
                child: Text('Start Glassbox'),
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: clearCache, // Button to clear cache
                child: Text('Clear Cache'),
              ),
              SizedBox(height: 20),
              Text('Connection Status: $connectionStatus'),
              Text('Device MAC Address: $macAddress'), // Display the MAC address
            ],
          ),
        ),
      ),
    );
  }

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

  Future<void> openWifiSettings() async {
    try {
      await platform.invokeMethod('openWifiSettings');
    } on PlatformException catch (e) {
      print("Failed to open Wi-Fi settings: '${e.message}'.");
    }
  }

  Future<void> connectToWifi() async {
    await requestLocationPermission(); // Make sure to await this
    await openWifiSettings(); // This will open the Wi-Fi settings page
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

  Future<void> checkWifiConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();

    setState(() {
      if (connectivityResult == ConnectivityResult.wifi) {
        connectionStatus = 'Connected to Wi-Fi';
      } else if (connectivityResult == ConnectivityResult.mobile) {
        connectionStatus = 'Connected to mobile data';
      } else {
        connectionStatus = 'Not connected to the internet';
      }
    });
  }

  Future<void> openDeveloperSetting() async {
    try {
      await platform.invokeMethod('openDeveloperOptions');
    } on PlatformException catch (e) {
      print("Failed to open developer options: '${e.message}'.");
    }
  }

  Future<void> startGlassbox() async {
    // context.read<AppProvider>().setSetting(setting);
    Navigator.pushNamed(context, '/login');
  }

  // Function to clear the cache
  Future<void> clearCache() async {
    try {
      await GbCacheManager().deleteCacheDir(); // Clears the cache
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cache cleared successfully!'))
      );
    } catch (e) {
      print("Failed to clear cache: $e");
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to clear cache'))
      );
    }
  }
}
