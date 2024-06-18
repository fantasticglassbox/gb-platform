import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glassbox/providers/ads.dart';
import 'package:glassbox/providers/app.dart';
import 'package:glassbox/providers/merchant.dart';
import 'package:glassbox/component/carousel.dart';
import 'package:glassbox/utils/shared_preference.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class Idle extends StatefulWidget {
  Idle({Key? key}) : super(key: key);

  @override
  _IdleState createState() => _IdleState();
}

class _IdleState extends State<Idle> {
  late TextEditingController _editingController;
  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    _editingController = TextEditingController();
  }

  @override
  void dispose() {
    _editingController.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  void _incrementPack() {
    if (_editingController.text.isNotEmpty) {
      int currentValue = int.parse(_editingController.text);
      currentValue++;
      _editingController.text = currentValue.toString();
    }
  }

  void _decrementPack() {
    setState(() {
      if (_editingController.text.isNotEmpty &&
          _editingController.text != '0') {
        int currentValue = int.parse(_editingController.text);
        currentValue--;
        _editingController.text = currentValue.toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: SafeArea(
          child: Center(
              child: Stack(
        children: [
          Carousel(ads: context.read<AdsProvider>().adsList),
          Positioned(
              bottom: 30.0,
              left: 30.0,
              child: Text(
                'Advertisement',
                style: TextStyle(fontSize: 10.sp, color: Colors.white),
              ))
        ],
      ))),
      floatingActionButton: context.read<AppProvider>().setting.enableOrdering
          ? FloatingActionButton.extended(
              backgroundColor: Theme.of(context).primaryColor,
              onPressed: () async {
                if (context.read<AppProvider>().sessionStatus == 'INACTIVE') {
                  final totalPack = await openDialog();
                  if (totalPack == null || totalPack.isEmpty) return;
                  if (context.mounted) {
                    var url =
                        Uri.https('api.glassbox.id', '/v1/sessions/start');
                    var body =
                        json.encode({'pax_number': int.parse(totalPack)});

                    final token = await _storage.readAll(
                      aOptions: getAndroidOptions(),
                    );

                    final response = await http.post(url,
                        headers: {
                          "Content-Type": "application/json",
                          'Authorization': 'Bearer ${token['access_token']}'
                        },
                        body: body);

                    if (response.statusCode >= 200 &&
                        response.statusCode <= 300) {
                      await _storage.write(
                          key: 'total_pack',
                          value: totalPack,
                          aOptions: getAndroidOptions());
                      context
                          .read<AppProvider>()
                          .setActiveNavigationRailIndex(0);
                      Navigator.pushReplacementNamed(context, '/main');
                    } else {
                      throw Exception('Failed to create session');
                    }
                  }
                } else {
                  Navigator.pushReplacementNamed(
                      context, context.read<AppProvider>().lastRoute);
                }
              },
              icon: const Icon(
                Icons.skip_next,
                color: Colors.white,
              ),
              label: Text(
                'Close Ad',
                style: TextStyle(color: Colors.white, fontSize: 14.sp),
              ),
            )
          : const SizedBox(),
    );
  }

  void closeDialog() {
    Navigator.of(context, rootNavigator: true).pop();

    _editingController.clear();
  }

  void submitPack() {
    Navigator.of(context).pop(_editingController.text);

    _editingController.clear();
  }

  Future<String?> openDialog() => showDialog<String>(
      // barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
            surfaceTintColor: Colors.white,
            title: Center(
                child: Text(
                    'Welcome to ${context.watch<MerchantProvider>().name}!',
                    style: TextStyle(fontSize: 14.sp))),
            content: SizedBox(
                width: 100.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        'To ensure we prepare your dining experience flawlessly, could you please let us know how many people youre ordering for?',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp)),
                    const SizedBox(
                      height: 10.0,
                    ),
                    SizedBox(
                      child: Row(
                        children: [
                          Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ValueListenableBuilder(
                                  valueListenable: _editingController,
                                  builder: (context, value, child) {
                                    return IconButton(
                                        onPressed: value.text.isNotEmpty &&
                                                value.text != '0'
                                            ? _decrementPack
                                            : null,
                                        icon: const Icon(Icons.remove));
                                  })),
                          Expanded(
                              child: TextField(
                            autofocus: true,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly
                            ],
                            controller: _editingController,
                            onSubmitted: (_) => submitPack(),
                            decoration: InputDecoration(
                              hintText: 'Enter your number',
                              enabledBorder: OutlineInputBorder(
                                borderSide:
                                    const BorderSide(color: Colors.grey),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderSide: const BorderSide(
                                  color: Colors.black,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              isDense: true,
                            ),
                          )),
                          Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: IconButton(
                                  onPressed: () {
                                    _incrementPack();
                                  },
                                  icon: const Icon(Icons.add))),
                        ],
                      ),
                    ),
                  ],
                )),
            actions: [
              Row(children: [
                Expanded(
                    child: ElevatedButton(
                        onPressed: closeDialog,
                        child:
                            Text('Cancel', style: TextStyle(fontSize: 14.sp)))),
                const SizedBox(
                  width: 10,
                ),
                Expanded(
                  child: ValueListenableBuilder(
                      valueListenable: _editingController,
                      builder: (context, value, child) {
                        return ElevatedButton(
                            onPressed:
                                value.text.isNotEmpty && value.text != '0'
                                    ? submitPack
                                    : null,
                            child: const Text('Proceed'));
                      }),
                )
              ]),
            ],
          ));
}
