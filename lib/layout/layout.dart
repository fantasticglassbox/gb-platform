import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassbox/providers/app.dart';
import 'package:glassbox/providers/cart.dart';
import 'package:idle_detector_wrapper/idle_detector_wrapper.dart';
import 'package:provider/provider.dart';

class MainLayout extends StatefulWidget {
  final Widget child;
  final Widget? drawer;
  const MainLayout({super.key, required this.child, this.drawer});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  @override
  Widget build(BuildContext context) {
    return IdleDetector(
        idleTime: const Duration(seconds: 120),
        onIdle: () {
          context
              .read<AppProvider>()
              .setLastRoute(ModalRoute.of(context)?.settings.name);
          Navigator.pushReplacementNamed(context, '/');
        },
        child: Scaffold(
            resizeToAvoidBottomInset: false,
            body: SafeArea(
              child: widget.child,
            ),
            endDrawer: widget.drawer,
            floatingActionButton: Badge(
              isLabelVisible:
                  context.watch<CartProvider>().cartItems['items'] != null,
              backgroundColor: const Color(0xffEEA23E),
              label: Text(
                  '${context.watch<CartProvider>().cartItems['items'] != null ? context.watch<CartProvider>().cartItems['items'].length : ''}',
                  style: TextStyle(fontSize: 14.sp)),
              child: FloatingActionButton(
                shape: const CircleBorder(),
                backgroundColor: const Color(0xff0A77FF),
                onPressed: () {
                  Navigator.pushNamed(context, '/cart');
                },
                child: const Icon(
                  Icons.shopping_cart,
                  size: 20.0,
                  color: Color(0xffFFFFFF),
                ),
              ),
            )));
  }
}
