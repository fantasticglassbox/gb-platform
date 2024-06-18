import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glassbox/model/ads.dart';
import 'package:glassbox/model/setting.dart';
import 'package:glassbox/providers/ads.dart';
import 'package:glassbox/providers/app.dart';
import 'package:glassbox/providers/merchant.dart';
import 'package:glassbox/utils/shared_preference.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _storage = const FlutterSecureStorage();
  static final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    initPlatformState();
  }

  Future<void> initPlatformState() async {
    var deviceData;
    String os = '';

    try {
      if (Platform.isAndroid) {
        deviceData = await deviceInfoPlugin.androidInfo;
        os = 'Android';
      } else if (Platform.isIOS) {
        deviceData = await deviceInfoPlugin.iosInfo;
        os = 'iOS';
      } else {
        return;
      }

      await login(
          deviceData.id, '${deviceData.brand}:${deviceData.device}', os, '{}');
    } on PlatformException {
      deviceData = <String, dynamic>{
        'Error:': 'Failed to get platform version.'
      };
    }

    if (!mounted) return;
  }

  Future login(String deviceId, String deviceName, String operatingSystem,
      String deviceDetail) async {
    var url = Uri.https('api.glassbox.id', 'v1/public/device/login');
    var body = json.encode({
      'device_id': deviceId,
      'device_name': deviceName,
      'operating_system': operatingSystem
    });
    final response = await http.post(url,
        headers: {"Content-Type": "application/json"}, body: body);

    var bodyData = json.decode(response.body);

    await _storage.write(
        key: 'access_token',
        value: bodyData['access_token'],
        aOptions: getAndroidOptions());

    if (response.statusCode == 200) {
      if (context.mounted) {
        context.read<MerchantProvider>().name =
            bodyData['account_info']['name'];
        context.read<MerchantProvider>().tagLine =
            bodyData['account_info']['tag_line'];
        context.read<MerchantProvider>().logoImage =
            bodyData['account_info']['logo'];
        context.read<MerchantProvider>().bannerImage =
            bodyData['account_info']['place_holder_image'];

        var urlSession = Uri.https('api.glassbox.id', '/v1/sessions/current');
        var settingConfig = Uri.https('api.glassbox.id', '/v1/settings');

        final responseSession = await http.post(urlSession, headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${bodyData['access_token']}'
        });

        final settingResponse = await http.get(settingConfig, headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${bodyData['access_token']}'
        });

        var bodyDataSession = json.decode(responseSession.body);

        String status = '';

        if (settingResponse.statusCode == 200) {
          var bodyDataSetting = json.decode(settingResponse.body);
          SettingModel setting = SettingModel(
              enableOrdering: bodyDataSetting['enable_ordering'],
              defaultImage: bodyDataSetting['default_image']);
          context.read<AppProvider>().setSetting(setting);
        }

        if (responseSession.statusCode >= 200 &&
            responseSession.statusCode <= 300) {
          status = bodyDataSession['status'];
          context
              .read<AppProvider>()
              .setSessionStatus(bodyDataSession['status']);
        } else {
          status = 'INACTIVE';
          context.read<AppProvider>().setSessionStatus('INACTIVE');
        }

        if (status == 'ACTIVE') {
          Navigator.pushNamed(context, '/main');
        } else if (status == 'INACTIVE') {
          var urlAds = Uri.https('api.glassbox.id', '/v1/merchants/ads');
          final response = await http.get(urlAds,
              headers: {'Authorization': 'Bearer ${bodyData['access_token']}'});

          final List responseBody = json.decode(response.body);

          if (response.statusCode == 200) {
            List<AdsModel> adsList =
                responseBody.map((e) => AdsModel.fromJSON(e)).toList();
            context.read<AdsProvider>().adsList = adsList;
            Navigator.pushNamed(context, '/');
          } else {
            throw Exception('Failed to load ads list');
          }
        }
      }
    } else {
      final snackBar = SnackBar(
        width: MediaQuery.of(context).size.width * 0.5,
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xff22762C),
        content: Center(child: Text('${bodyData['error']}')),
      );

      ScaffoldMessenger.of(context).showSnackBar(snackBar);
      await Future.delayed(const Duration(seconds: 3));
      SystemNavigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
