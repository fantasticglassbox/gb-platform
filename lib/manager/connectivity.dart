import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';

class GbConnectivity {
  Future<bool> hasNetwork() async {
    try {
      final result = await InternetAddress.lookup('api.glassbox.id');
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    }
  }

  Future<bool> isConnectedToWifi() async {
    ConnectivityResult connectivityResult = await Connectivity()
        .checkConnectivity();
    if (connectivityResult == ConnectivityResult.wifi) {
      return true;
    } else {
      return false;
    }
  }
}