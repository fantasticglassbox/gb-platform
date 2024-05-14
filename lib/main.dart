import 'package:flutter/material.dart';
import 'package:glassbox/pages/cart.dart';
import 'package:glassbox/pages/login.dart';
import 'package:glassbox/pages/main.dart';
import 'package:glassbox/providers/ads.dart';
import 'package:glassbox/providers/app.dart';
import 'package:glassbox/providers/cart.dart';
import 'package:glassbox/providers/menu.dart';
import 'package:glassbox/providers/merchant.dart';
import 'package:glassbox/pages/idle.dart';
import 'package:glassbox/theme.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

void main() {
  runApp(MultiProvider(providers: [
    ChangeNotifierProvider(create: (_) => AppProvider()),
    ChangeNotifierProvider(create: (_) => MerchantProvider()),
    ChangeNotifierProvider(create: (_) => AdsProvider()),
    ChangeNotifierProvider(create: (_) => MenuProvider()),
    ChangeNotifierProvider(create: (_) => CartProvider()),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1280, 800),
      builder: (context, child) {
        return MaterialApp(
          title: 'Glassbox',
          debugShowCheckedModeBanner: false,
          theme: appTheme,
          initialRoute: '/login',
          routes: {
            '/': (context) => Idle(),
            '/main': (context) => MainPage(),
            '/login': (context) => const LoginPage(),
            '/cart': (context) => const CartPage(),
          },
        );
      },
    );
  }
}
