import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:glassbox/component/menu_category.dart';
import 'package:glassbox/component/menu_drawer.dart';
import 'package:glassbox/providers/app.dart';
import 'package:glassbox/providers/cart.dart';
import 'package:glassbox/providers/menu.dart';
import 'package:glassbox/utils/currency.dart';
import 'package:glassbox/utils/shared_preference.dart';
import 'package:http/http.dart' as http;
import 'package:idle_detector_wrapper/idle_detector_wrapper.dart';
import 'package:provider/provider.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  final _storage = const FlutterSecureStorage();
  final _formKey = GlobalKey<FormBuilderState>();
  int currentQuantityItem = 0;
  String currentItemNote = '';
  bool isLoading = false;
  int selectedCartIndex = -1;

  late Future<Map> futureCart;

  Future<Map> getCartList() async {
    var url = Uri.https('api.glassbox.id', '/v1/carts/current');
    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );
    final response = await http.get(url,
        headers: {'Authorization': 'Bearer ${token['access_token']}'});

    final Map responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      return responseBody;
    } else {
      throw Exception('Failed to load current cart list');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    futureCart = getCartList();
  }

  List<Widget> renderModifiers(Map modifers) {
    List<Widget> widgets = [];
    for (var item in modifers.keys) {
      List names = [];
      for (var i = 0; i < modifers[item].length; i++) {
        names.add(modifers[item][i]['name']);
      }
      String values = names.join(', ');
      widgets.add(Text('$item: $values', style: TextStyle(fontSize: 16.sp)));
    }

    return widgets;
  }

  Future checkOut() async {
    setState(() {
      isLoading = true;
    });
    var url = Uri.https('api.glassbox.id', '/v1/carts/checkout');
    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );
    final response = await http.post(url,
        headers: {'Authorization': 'Bearer ${token['access_token']}'});

    final Map responseBody = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode <= 200) {
      return responseBody;
    } else {
      return null;
    }
  }

  Widget renderImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      return Image.asset('images/default-menu.jpg',
          width: 128, height: 128, fit: BoxFit.cover);
    } else {
      return Image.network(imageUrl,
          width: 128, height: 128, fit: BoxFit.cover);
    }
  }

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
            appBar: AppBar(
              backgroundColor: Colors.white,
              title: const Text('Order Cart'),
              centerTitle: true,
              surfaceTintColor: Colors.white,
              actions: [Container()],
            ),
            endDrawer: MenuDrawer(
              menuId: context.watch<MenuProvider>().activeMenu['menuId'],
              quantity: currentQuantityItem,
              note: currentItemNote,
              cartIndex: selectedCartIndex,
            ),
            onEndDrawerChanged: (isOpened) {
              if (!isOpened) {
                setState(() {
                  futureCart = getCartList();
                  selectedCartIndex = -1;
                });
              }
            },
            bottomNavigationBar: Container(
              padding: const EdgeInsets.all(8.0),
              clipBehavior: Clip.antiAlias,
              decoration: const BoxDecoration(color: Colors.white, boxShadow: [
                BoxShadow(
                  offset: Offset(
                    5.0,
                    5.0,
                  ),
                  blurRadius: 5.0,
                  spreadRadius: 2.0,
                ),
              ]),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Expanded(
                      child: FutureBuilder(
                          future: futureCart,
                          builder: (context, snapshot) {
                            if (snapshot.hasData) {
                              final data = snapshot.data;
                              return Row(
                                children: [
                                  Text('Grand Total',
                                      style: TextStyle(fontSize: 16.sp)),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    CurrencyFormat.convertToIdr(
                                        data?['sub_total']['value'], 0),
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 22.sp),
                                  ),
                                ],
                              );
                            }

                            return const Text('');
                          })),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        foregroundColor: Theme.of(context)
                            .primaryColor, //change background color of button
                        backgroundColor:
                            const Color.fromRGBO(234, 244, 252, 1)),
                    onPressed: () {
                      context
                          .read<AppProvider>()
                          .setActiveNavigationRailIndex(1);
                      Navigator.pushNamed(context, '/main');
                    },
                    child: Text('Add More', style: TextStyle(fontSize: 16.sp)),
                  ),
                  const SizedBox(
                    width: 20,
                  ),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          foregroundColor:
                              Colors.white, //change background color of button
                          backgroundColor: Theme.of(context).primaryColor),
                      onPressed: context
                                  .read<CartProvider>()
                                  .cartItems['items'] ==
                              null
                          ? null
                          : () {
                              checkOut().then((value) {
                                setState(() {
                                  isLoading = false;
                                });
                                if (value == null) {
                                  final snackBar = SnackBar(
                                    width:
                                        MediaQuery.of(context).size.width * 0.5,
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xffFF453A),
                                    content: const Center(
                                        child: Text(
                                            "We're experiencing a slight issue on our end. Please retry.")),
                                  );

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);
                                } else {
                                  final snackBar = SnackBar(
                                    width:
                                        MediaQuery.of(context).size.width * 0.5,
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: const Color(0xff22762C),
                                    content: const Center(
                                        child: Text(
                                            'Your orders have been successfully submitted.')),
                                  );

                                  ScaffoldMessenger.of(context)
                                      .showSnackBar(snackBar);

                                  context
                                      .read<AppProvider>()
                                      .setActiveNavigationRailIndex(2);
                                  Navigator.pushNamed(context, '/main');
                                }
                              });
                            },
                      child: isLoading
                          ? const SizedBox(
                              height: 15,
                              width: 15,
                              child: CircularProgressIndicator(),
                            )
                          : Text('Proceed to Checkout',
                              style: TextStyle(fontSize: 16.sp)))
                ],
              ),
            ),
            body: SafeArea(
                child: FutureBuilder(
                    future: futureCart,
                    builder: ((context, snapshot) {
                      if (snapshot.hasData) {
                        final cartList = snapshot.data;
                        if (cartList?['items'] != null) {
                          return Container(
                              padding: const EdgeInsets.only(
                                  top: 16.0, left: 16.0, right: 16.0),
                              color: const Color.fromRGBO(247, 247, 247, 1.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      color: Colors.white,
                                      padding: const EdgeInsets.all(16.0),
                                      child: FormBuilder(
                                        key: _formKey,
                                        clearValueOnUnregister: true,
                                        child: ListView.builder(
                                          itemBuilder: (context, index) {
                                            return Container(
                                                padding:
                                                    const EdgeInsets.all(16.0),
                                                child: Column(
                                                  children: [
                                                    Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        renderImage(
                                                            cartList!['items']
                                                                    [index]
                                                                ['image']),
                                                        const SizedBox(
                                                          width: 16.0,
                                                        ),
                                                        Expanded(
                                                            child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              CurrencyFormat.convertToIdr(
                                                                  cartList?['items']
                                                                              [
                                                                              index]
                                                                          [
                                                                          'price']
                                                                      ['value'],
                                                                  0),
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .w600,
                                                                  fontSize:
                                                                      20.sp),
                                                            ),
                                                            const SizedBox(
                                                              height: 10,
                                                            ),
                                                            Text(
                                                              cartList?['items']
                                                                      [index]
                                                                  ['name'],
                                                              style: TextStyle(
                                                                  fontSize:
                                                                      20.sp),
                                                            ),
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                ...renderModifiers(
                                                                    cartList?['items']
                                                                            [
                                                                            index]
                                                                        [
                                                                        'modifiers'])
                                                              ],
                                                            ),
                                                            Text(
                                                                'Note: ${cartList?['items'][index]['note']}',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        16.sp)),
                                                            const SizedBox(
                                                              height: 20,
                                                            ),
                                                            Text(
                                                                'Quantity: ${cartList?['items'][index]['quantity']}',
                                                                style: TextStyle(
                                                                    fontSize:
                                                                        16.sp)),
                                                          ],
                                                        )),
                                                        IconButton(
                                                            onPressed: () {
                                                              Map activeMenu = {
                                                                'menuId': cartList?[
                                                                            'items']
                                                                        [index]
                                                                    ['menu_id'],
                                                                'menuName':
                                                                    cartList?['items']
                                                                            [
                                                                            index]
                                                                        [
                                                                        'name'],
                                                                'menuImage':
                                                                    cartList?['items']
                                                                            [
                                                                            index]
                                                                        [
                                                                        'image'],
                                                                'menuDescription':
                                                                    '',
                                                                'menuPrice': cartList?[
                                                                            'items']
                                                                        [index][
                                                                    'price']['value'],
                                                                'menuDiscount':
                                                                    0,
                                                                'menuCategories':
                                                                    [],
                                                                'menuPriceAfterDiscount':
                                                                    0,
                                                              };
                                                              setState(() {
                                                                selectedCartIndex =
                                                                    index;
                                                                currentItemNote =
                                                                    cartList?['items']
                                                                            [
                                                                            index]
                                                                        [
                                                                        'note'];
                                                                currentQuantityItem =
                                                                    cartList?['items']
                                                                            [
                                                                            index]
                                                                        [
                                                                        'quantity'];
                                                              });
                                                              context
                                                                  .read<
                                                                      MenuProvider>()
                                                                  .setActiveMenu(
                                                                      activeMenu);
                                                              Scaffold.of(
                                                                      context)
                                                                  .openEndDrawer();
                                                            },
                                                            icon: FaIcon(
                                                              FontAwesomeIcons
                                                                  .pencil,
                                                              color: Theme.of(
                                                                      context)
                                                                  .primaryColor,
                                                              size: 16,
                                                            ))
                                                      ],
                                                    ),
                                                    const SizedBox(
                                                      height: 16,
                                                    ),
                                                    const Divider(),
                                                  ],
                                                ));
                                          },
                                          itemCount: cartList?['items'].length,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                    width: 16,
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: Container(
                                      color: Colors.white,
                                      padding: const EdgeInsets.all(16.0),
                                      child: ListView.builder(
                                        itemBuilder: (context, index) {
                                          return LayoutBuilder(
                                              builder: (context, constraints) {
                                            final width = constraints.maxWidth;
                                            bool showAsGrid = false;
                                            double cardAspectRatio = 2.7;
                                            if (width <= 220) {
                                              showAsGrid = true;
                                              cardAspectRatio = 1.1;
                                            }
                                            return MenuCategory(
                                              categoryId: context
                                                  .watch<MenuProvider>()
                                                  .recommendedCategory,
                                              categoryName: 'Recommended',
                                              categoryIcon: 'recommended',
                                              showAsGrid: showAsGrid,
                                              cardAspectRatio: cardAspectRatio,
                                              crossAxisCount: 1,
                                              imageSize: 100,
                                            );
                                          });
                                        },
                                        itemCount: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ));
                        } else {
                          return Container(
                            padding: const EdgeInsets.all(16.0),
                            color: const Color.fromRGBO(247, 247, 247, 1.0),
                            child: Container(
                              color: Colors.white,
                              padding: const EdgeInsets.all(16.0),
                              child: SingleChildScrollView(
                                  child: Column(
                                children: [
                                  const Center(
                                    child: FaIcon(
                                      FontAwesomeIcons.cartShopping,
                                      size: 90.0,
                                      color: Color(0xffC1C3C7),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 16.0,
                                  ),
                                  Center(
                                    child: Text(
                                        'Ready to feast? Start filling your cart with delicious delights now!',
                                        style: TextStyle(fontSize: 16.sp)),
                                  ),
                                  const SizedBox(
                                    height: 16.0,
                                  ),
                                  ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          foregroundColor: Colors
                                              .white, //change background color of button
                                          backgroundColor:
                                              Theme.of(context).primaryColor),
                                      onPressed: () {
                                        Navigator.pushNamed(context, '/main');
                                      },
                                      child: Wrap(
                                        crossAxisAlignment:
                                            WrapCrossAlignment.center,
                                        children: [
                                          Text('Add',
                                              style:
                                                  TextStyle(fontSize: 16.sp)),
                                          const SizedBox(
                                            width: 10,
                                          ),
                                          const FaIcon(
                                            FontAwesomeIcons.plus,
                                            size: 16,
                                          ),
                                        ],
                                      )),
                                  const SizedBox(
                                    height: 50,
                                  ),
                                  LayoutBuilder(
                                      builder: (context, constraints) {
                                    final width = constraints.maxWidth;
                                    int crossAxisCount = 4;
                                    double cardAspectRatio = 1.9;
                                    if (width <= 736) {
                                      crossAxisCount = 2;
                                      cardAspectRatio = 3.3;
                                    }
                                    return MenuCategory(
                                      categoryId: context
                                          .watch<MenuProvider>()
                                          .recommendedCategory,
                                      categoryName: 'Recommended',
                                      categoryIcon: 'recommended',
                                      showAsGrid: false,
                                      cardAspectRatio: cardAspectRatio,
                                      crossAxisCount: crossAxisCount,
                                    );
                                  })
                                ],
                              )),
                            ),
                          );
                        }
                      }

                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    })))));
  }
}
