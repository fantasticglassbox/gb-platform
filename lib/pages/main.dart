import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:glassbox/pages/bill.dart';
import 'package:glassbox/pages/home.dart';
import 'package:glassbox/pages/menu.dart';
import 'package:glassbox/providers/app.dart';
import 'package:glassbox/providers/cart.dart';
import 'package:glassbox/providers/merchant.dart';
import 'package:glassbox/utils/shared_preference.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class MainPage extends StatefulWidget {
  MainPage({Key? key}) : super(key: key);

  @override
  _MainPageState createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final padding = 8.0;
  final _storage = const FlutterSecureStorage();
  bool isLoading = false;

  Future getCartList() async {
    var url = Uri.https('api.glassbox.id', '/v1/carts/current');
    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );
    final response = await http.get(url,
        headers: {'Authorization': 'Bearer ${token['access_token']}'});

    final Map responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      context.read<CartProvider>().setCart(responseBody);
    } else {
      throw Exception('Failed to load current cart list');
    }
  }

  Future terminateSession() async {
    setState(() {
      isLoading = true;
    });
    var url = Uri.https('api.glassbox.id', '/v1/sessions/end');

    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );

    final response = await http.post(url, headers: {
      "Content-Type": "application/json",
      'Authorization': 'Bearer ${token['access_token']}'
    });

    if (response.statusCode >= 200 && response.statusCode <= 300) {
      return true;
    } else {
      return false;
    }
  }

  void closeDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<String?> openDialog() => showDialog<String>(
      // barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
            surfaceTintColor: Colors.white,
            title: Center(
              child: Text('Terminate the Session?',
                  style: TextStyle(fontSize: 14.sp)),
            ),
            content: SizedBox(
                width: 150.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        'Are you certain you want to terminate this session? This device will become idle shortly.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp)),
                    const SizedBox(
                      height: 10.0,
                    ),
                  ],
                )),
            actions: [
              Row(
                children: [
                  Expanded(
                      child: ElevatedButton(
                          onPressed: () {
                            closeDialog();
                          },
                          child: Text('Cancel',
                              style: TextStyle(fontSize: 14.sp)))),
                  const SizedBox(
                    width: 10,
                  ),
                  // StatefulBuilder(builder: (context, setState) {}
                  StatefulBuilder(builder: (context, setState) {
                    return Expanded(
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                foregroundColor: Colors
                                    .white, //change background color of button
                                backgroundColor: Colors.red),
                            onPressed: () {
                              terminateSession().then((value) {
                                if (value) {
                                  context
                                      .read<AppProvider>()
                                      .setSessionStatus('INACTIVE');
                                  Navigator.pushNamed(context, '/');
                                } else {
                                  final snackBar = SnackBar(
                                    width:
                                        MediaQuery.of(context).size.width * 0.5,
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xffFF453A),
                                    content: Center(
                                        child: Text('Failed to close session',
                                            style: TextStyle(fontSize: 14.sp))),
                                  );
                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                }
                              });
                            },
                            child: isLoading
                                ? const SizedBox(
                                    height: 15,
                                    width: 15,
                                    child: CircularProgressIndicator(),
                                  )
                                : Text('Terminate',
                                    style: TextStyle(fontSize: 14.sp))));
                  })
                ],
              )
            ],
          ));

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getCartList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Row(
        children: [
          Stack(children: [
            NavigationRail(
              groupAlignment: 0.0,
              minWidth: 100.0,
              backgroundColor: const Color(0xff252525),
              destinations: [
                buildRailDestination('Home', padding, const Icon(Icons.home)),
                buildRailDestination(
                    'Order', padding, const Icon(Icons.restaurant)),
                buildRailDestination('Bill', padding, const Icon(Icons.receipt))
              ],
              selectedIndex:
                  context.read<AppProvider>().activeNavigationRailIndex,
              onDestinationSelected: (int index) {
                context.read<AppProvider>().setActiveNavigationRailIndex(index);
              },
              labelType: NavigationRailLabelType.all,
              leading: Column(
                children: [
                  SizedBox(height: 8),
                  Center(
                    child: CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(
                          context.watch<MerchantProvider>().logoImage),
                    ),
                  ),
                ],
              ),
              selectedLabelTextStyle: const TextStyle(
                color: Color(0xffFCFCFD),
                fontSize: 13,
                letterSpacing: 0.8,
                fontWeight: FontWeight.bold,
              ),
              selectedIconTheme: const IconThemeData(color: Color(0xffFCFCFD)),
              unselectedIconTheme:
                  const IconThemeData(color: Color(0xffE5E5E7)),
              unselectedLabelTextStyle: const TextStyle(
                fontSize: 13,
                color: Color(0xffE5E5E7),
                letterSpacing: 0.8,
              ),
              useIndicator: true,
              indicatorColor: const Color(0xff525D6A),
            ),
            Positioned(
              bottom: 10,
              width: 100.0,
              child: Column(children: [
                Center(
                  child: Text(
                    'v1.0.0',
                    style: TextStyle(
                        color: const Color.fromRGBO(144, 144, 144, 1),
                        fontSize: 14.sp),
                  ),
                ),
                const SizedBox(
                  height: 10,
                ),
                Center(
                  child: IconButton(
                      onPressed: () {
                        openDialog();
                      },
                      icon: const FaIcon(
                        FontAwesomeIcons.powerOff,
                        color: Color(0xffA1A4AC),
                      )),
                )
              ]),
            )
          ]),
          Expanded(
              child: _renderChild(
                  context.watch<AppProvider>().activeNavigationRailIndex))
        ],
      ),
    );
  }

  Widget _renderChild(index) {
    switch (index) {
      case 0:
        return Home();
      case 1:
        return const MenuPage();
      case 2:
        return const BillPage();
      default:
        return const Text('404 Page');
    }
  }
}

NavigationRailDestination buildRailDestination(
    String text, double padding, Icon icon) {
  return NavigationRailDestination(
      icon: icon,
      label: Text(text, style: TextStyle(fontSize: 14.sp)),
      padding: const EdgeInsets.only(top: 10, bottom: 10));
}
