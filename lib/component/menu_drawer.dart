import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:glassbox/model/menu_modifier.dart';
import 'package:glassbox/providers/cart.dart';
import 'package:glassbox/providers/menu.dart';
import 'package:glassbox/utils/currency.dart';
import 'package:glassbox/utils/icon.dart';
import 'package:glassbox/utils/shared_preference.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class MenuDrawer extends StatefulWidget {
  final String menuId;
  int cartIndex;
  int? quantity;
  String? note;
  MenuDrawer(
      {super.key,
      required this.menuId,
      this.cartIndex = -1,
      this.quantity,
      this.note});

  @override
  State<MenuDrawer> createState() => _MenuDrawerState();
}

class _MenuDrawerState extends State<MenuDrawer> {
  late TextEditingController _editingTotal;
  int totalMenuPrice = 0;
  int totalModifierPrice = 0;
  List textEditingControllers = <TextEditingController>[];
  List isMenuChecked = [];
  List formController = [];
  late TextEditingController _noteEditingController;
  final _storage = const FlutterSecureStorage();
  bool isSubmitting = false;
  Map itemCart = {};
  bool isModifierFetched = false;
  late Future<List<MenuModifierModel>> futureModifier;

  final _formKey = GlobalKey<FormBuilderState>();
  final List<Widget> fields = [];
  Map<String, dynamic> formValues = {};

  Future<List<MenuModifierModel>> getMenuModifier() async {
    var url =
        Uri.https('api.glassbox.id', '/v1/menus/modifier/${widget.menuId}');
    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );
    final response = await http.get(url,
        headers: {'Authorization': 'Bearer ${token['access_token']}'});

    final List responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      List<MenuModifierModel> menuModifier =
          responseBody.map((e) => MenuModifierModel.fromJSON(e)).toList();
      return menuModifier;
    } else {
      throw Exception('Failed to menu modifier list');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    if (widget.quantity != null) {
      _editingTotal = TextEditingController(text: '${widget.quantity}');
      setState(() {
        totalMenuPrice = context.read<MenuProvider>().activeMenu['menuPrice'] *
            widget.quantity;
      });
    } else {
      _editingTotal = TextEditingController(text: '0');
    }

    if (widget.note != null) {
      _noteEditingController = TextEditingController(text: widget.note);
    } else {
      _noteEditingController = TextEditingController();
    }

    if (widget.cartIndex != -1) {
      List cartItems = context.read<CartProvider>().cartItems['items'];
      setState(() {
        itemCart = cartItems[widget.cartIndex];
      });
    }

    futureModifier = getMenuModifier().then((value) {
      if (itemCart.isNotEmpty) {
        if (itemCart['note'] != '') {
          _noteEditingController =
              TextEditingController(text: itemCart['note']);
        }

        if (itemCart['quantity'] != 0) {
          _editingTotal =
              TextEditingController(text: '${itemCart['quantity']}');
          setState(() {
            totalMenuPrice =
                context.read<MenuProvider>().activeMenu['menuPrice'] *
                    itemCart['quantity'];
          });
        }
      }
      return value;
    });
  }

  @override
  void dispose() {
    _editingTotal.dispose();
    _noteEditingController.dispose();
    // TODO: implement dispose
    super.dispose();
  }

  void _incrementPackTotal() {
    if (_editingTotal.text.isNotEmpty) {
      int currentValue = int.parse(_editingTotal.text);
      currentValue++;
      _editingTotal.text = currentValue.toString();
      setState(() {
        totalMenuPrice =
            context.read<MenuProvider>().activeMenu['menuPrice'] * currentValue;
      });
    }
  }

  void _decrementPackTotal() {
    setState(() {
      if (_editingTotal.text.isNotEmpty && _editingTotal.text != '0') {
        int currentValue = int.parse(_editingTotal.text);
        currentValue--;
        _editingTotal.text = currentValue.toString();
        totalMenuPrice =
            context.read<MenuProvider>().activeMenu['menuPrice'] * currentValue;
      }
    });
  }

  bool isRadioSelection(int minSelection, int maxSelection) {
    return minSelection == maxSelection;
  }

  Future handleDeleteCart() async {
    setState(() {
      isSubmitting = true;
    });
    var url = Uri.https('api.glassbox.id', '/v1/carts/${itemCart['id']}');
    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );
    final response = await http.delete(url,
        headers: {'Authorization': 'Bearer ${token['access_token']}'});

    if (response.statusCode >= 200 && response.statusCode <= 300) {
      return true;
    } else {
      return null;
    }
  }

  void handlePressButton() async {
    if (_formKey.currentState!.saveAndValidate()) {
      setState(() {
        formValues = _formKey.currentState?.value ?? {};
        isSubmitting = true;
      });

      List modifiers = [];
      List normalizeFormValues = [];

      for (var item in formValues.keys) {
        if (item.contains('radio_')) {
          modifiers.add(formValues[item]);
          normalizeFormValues.add(formValues[item]);
        } else if (item.contains('checkbox_')) {
          formValues[item].forEach((value) {
            modifiers.add(value);
          });
          normalizeFormValues.add(formValues[item]);
        }
      }

      Color snackbarColor = const Color(0xff22762C);
      String snackbarText = 'Successfully added to cart';

      final snackBar = SnackBar(
        width: MediaQuery.of(context).size.width * 0.5,
        behavior: SnackBarBehavior.floating,
        backgroundColor: snackbarColor,
        content: Center(child: Text(snackbarText)),
        // action: SnackBarAction(
        //   textColor: Colors.white,
        //   label: 'View cart',
        //   onPressed: () {
        //     Navigator.of(context, rootNavigator: true).pushNamed('/cart');
        //   },
        // ),
      );

      context.read<MenuProvider>().addToCart({
        'menu_id': widget.menuId,
        'quantity': int.parse(_editingTotal.text),
        'note': _noteEditingController.text,
        'modifiers': modifiers,
        'form_values': normalizeFormValues,
      });

      Map requestBody = {
        'menu_id': widget.menuId,
        'quantity': int.parse(_editingTotal.text),
        'note': _noteEditingController.text,
        'modifiers': modifiers
      };

      if (itemCart.isNotEmpty) {
        updateCart(requestBody).then((value) {
          if (value == null) {
            final snackBar = SnackBar(
              width: MediaQuery.of(context).size.width * 0.5,
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xffFF453A),
              content: const Center(
                  child: Text(
                      "We're experiencing a slight issue on our end. Please retry.")),
            );

            ScaffoldMessenger.of(context).showSnackBar(snackBar);
            setState(() {
              isSubmitting = false;
            });
          } else {
            getCartList().then((value) {
              setState(() {
                isSubmitting = false;
              });
              final snackBar = SnackBar(
                width: MediaQuery.of(context).size.width * 0.5,
                behavior: SnackBarBehavior.floating,
                backgroundColor: const Color(0xff22762C),
                content: const Center(child: Text('Successfully update items')),
              );

              ScaffoldMessenger.of(context).showSnackBar(snackBar);
              Scaffold.of(context).closeEndDrawer();
            });
          }
        });
      } else {
        await addToCart(requestBody).then((value) {
          getCartList().then((value) {
            setState(() {
              isSubmitting = false;
            });
            Scaffold.of(context).closeEndDrawer();
          });
          ScaffoldMessenger.of(context).showSnackBar(snackBar);
        });
      }
    }
    // On another side, can access all field values without saving form with instantValues
    // _formKey.currentState?.validate();
    // debugPrint(_formKey.currentState?.instantValue.toString());
  }

  Future updateCart(Map requestBody) async {
    var url = Uri.https('api.glassbox.id', '/v1/carts/${itemCart['id']}');
    var body = json.encode(requestBody);

    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );

    final response = await http.put(url,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${token['access_token']}'
        },
        body: body);

    var bodyData = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode <= 300) {
      return bodyData;
    } else {
      return null;
    }
  }

  Future addToCart(Map requestBody) async {
    var url = Uri.https('api.glassbox.id', 'v1/carts');
    var body = json.encode(requestBody);

    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );

    final response = await http.post(url,
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${token['access_token']}'
        },
        body: body);

    var bodyData = json.decode(response.body);

    return bodyData;
  }

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
      return true;
    } else {
      return false;
    }
  }

  List<Widget> renderModifierFields(List<MenuModifierModel> modifiers) {
    List<Widget> modifiersFields = [];
    for (var i = 0; i < modifiers.length; i++) {
      if (isRadioSelection(
          modifiers[i].minimumSelectable, modifiers[i].maximumSelectable)) {
        List options = [];
        if (modifiers[i].modifierOption != null) {
          options = modifiers[i].modifierOption;
        }

        Widget field = Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      modifiers[i].name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 18.0),
                    ),
                  ),
                  Text(
                    modifiers[i].required ? 'Required' : 'Optional',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ],
              ),
              FormBuilderRadioGroup(
                decoration: const InputDecoration(border: InputBorder.none),
                validator: modifiers[i].required
                    ? FormBuilderValidators.compose(
                        [FormBuilderValidators.required()])
                    : null,
                options: options
                    .map((val) => FormBuilderFieldOption(
                        value: val['modifier_option_id'],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              val['name'],
                              style: TextStyle(fontSize: 16.sp),
                            ),
                            val['price'] == '0'
                                ? Text('Free',
                                    style: TextStyle(fontSize: 16.sp))
                                : Text(
                                    CurrencyFormat.convertToIdr(
                                        int.parse(val['price']), 0),
                                    style: TextStyle(fontSize: 16.sp))
                          ],
                        )))
                    .toList(),
                name: 'radio_$i',
                orientation: OptionsOrientation.vertical,
              ),
            ],
          ),
        );

        modifiersFields.add(field);
      } else {
        List modifierOption = modifiers[i].modifierOption;
        // for (var j = 0; j < modifierOption.length; j++) {
        //   var textEditingController = TextEditingController(text: '0');
        //   textEditingControllers.add(textEditingController);
        //   isMenuChecked.add(false);
        // }
        Widget field = Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      modifiers[i].name,
                      style: TextStyle(
                          fontWeight: FontWeight.w500, fontSize: 18.sp),
                    ),
                  ),
                  Text(
                    modifiers[i].required ? 'Required' : 'Optional',
                    style: TextStyle(fontSize: 12.sp),
                  ),
                ],
              ),
              FormBuilderCheckboxGroup<dynamic>(
                onChanged: (value) {
                  int modiferPrice = 0;
                  for (var item in value!) {
                    for (var modifier in modifierOption) {
                      if (item == modifier['modifier_option_id']) {
                        modiferPrice += int.parse(modifier['price']);
                      }
                    }
                  }

                  setState(() {
                    totalModifierPrice = modiferPrice;
                  });
                },
                decoration: const InputDecoration(border: InputBorder.none),
                options: modifierOption
                    .map((val) => FormBuilderFieldOption(
                        value: val['modifier_option_id'],
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(val['name']),
                            val['price'] == '0'
                                ? Text('Free',
                                    style: TextStyle(fontSize: 16.sp))
                                : Text(
                                    CurrencyFormat.convertToIdr(
                                        int.parse(val['price']), 0),
                                    style: TextStyle(fontSize: 16.sp))
                          ],
                        )))
                    .toList(),
                name: 'checkbox_$i',
                validator: modifiers[i].required
                    ? FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                      ])
                    : null,
              ),
            ],
          ),
        );

        modifiersFields.add(field);
      }
    }

    return modifiersFields;
  }

  List<Widget> renderCategoryIcon(dynamic categories) {
    if (categories is List) {
      return categories.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GBIcon.getIcon(item['icon']),
        );
      }).toList();
    } else {
      List listCat = categories.split(',');
      return listCat.map((item) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GBIcon.getIcon(item),
        );
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      double widthFactor = 0.4;
      if (width <= 800) {
        widthFactor = 0.6;
      }
      return Drawer(
        width: MediaQuery.of(context).size.width * widthFactor,
        child: SafeArea(
            child: Column(
          children: [
            Expanded(
              flex: 1,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                    top: 16,
                    left: 16,
                    right: 16,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 50),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Image.network(
                            // 'https://gbstorage.sgp1.digitaloceanspaces.com/assets/dev/a/f89c0d84ed1db2e3.png',
                            context
                                        .watch<MenuProvider>()
                                        .activeMenu['menuImage'] !=
                                    ''
                                ? context
                                    .watch<MenuProvider>()
                                    .activeMenu['menuImage']
                                : 'https://placehold.co/200/png',
                            width: double.infinity,
                            height: 218,
                            fit: BoxFit.cover),
                        Positioned(
                            right: 10,
                            top: 10,
                            child: Container(
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  color: Colors.white,
                                  boxShadow: const [
                                    BoxShadow(
                                        color: Colors.white, spreadRadius: 3)
                                  ]),
                              child: Row(
                                children: [
                                  ...renderCategoryIcon(context
                                      .watch<MenuProvider>()
                                      .activeMenu['menuCategories']),
                                ],
                              ),
                            ))
                      ],
                    ),
                    Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            context
                                        .watch<MenuProvider>()
                                        .activeMenu['menuDiscount'] !=
                                    0
                                ? Row(
                                    children: [
                                      Text(
                                        CurrencyFormat.convertToIdr(
                                            context
                                                .watch<MenuProvider>()
                                                .activeMenu['menuPrice'],
                                            0),
                                        style: TextStyle(
                                            fontSize: 16.sp,
                                            decoration:
                                                TextDecoration.lineThrough),
                                      ),
                                      const SizedBox(
                                        width: 10.0,
                                      ),
                                      Text(
                                        '-${context.watch<MenuProvider>().activeMenu['menuDiscount']}%',
                                        style: TextStyle(
                                            fontSize: 14.sp,
                                            color: Color(0xffEEA23E),
                                            backgroundColor: Color(0xffFDEFDC)),
                                      )
                                    ],
                                  )
                                : const SizedBox(),
                            Text(
                              context
                                          .watch<MenuProvider>()
                                          .activeMenu['menuDiscount'] ==
                                      0
                                  ? CurrencyFormat.convertToIdr(
                                      context
                                          .watch<MenuProvider>()
                                          .activeMenu['menuPrice'],
                                      0)
                                  : CurrencyFormat.convertToIdr(
                                      context
                                          .watch<MenuProvider>()
                                          .activeMenu['menuPriceAfterDiscount'],
                                      0),
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 22.sp),
                            ),
                            Text(
                              context
                                  .watch<MenuProvider>()
                                  .activeMenu['menuName'],
                              style: TextStyle(
                                  fontSize: 20.sp, fontWeight: FontWeight.w500),
                            ),
                            Text(
                                context
                                    .watch<MenuProvider>()
                                    .activeMenu['menuDescription'],
                                style: TextStyle(fontSize: 16.sp)),
                            const SizedBox(
                              height: 20,
                            ),
                            FutureBuilder(
                                future: futureModifier,
                                builder: ((context, snapshot) {
                                  if (snapshot.hasData) {
                                    final data = snapshot.data;

                                    WidgetsBinding.instance
                                        .addPostFrameCallback((_) {
                                      if (!isModifierFetched) {
                                        if (itemCart.isNotEmpty) {
                                          // TODO: WILL MAKE IT DYNAMIC
                                          Map<String, dynamic> formValue = {};
                                          for (var key
                                              in itemCart['modifiers'].keys) {
                                            if (key == 'Spicy Level') {
                                              formValue['radio_0'] =
                                                  itemCart['modifiers'][key][0]
                                                      ['modifier_option_id'];
                                            } else if (key == 'Topping') {
                                              formValue['checkbox_1'] =
                                                  itemCart['modifiers'][key]
                                                      .map((item) => item[
                                                          'modifier_option_id'])
                                                      .toList();
                                            }
                                          }

                                          _formKey.currentState
                                              ?.patchValue(formValue);
                                        }

                                        setState(() {
                                          isModifierFetched = true;
                                        });
                                      }
                                    });

                                    return FormBuilder(
                                      key: _formKey,
                                      clearValueOnUnregister: true,
                                      child: Column(
                                        children: [
                                          ...renderModifierFields(data!),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          FormBuilderTextField(
                                            name: 'note',
                                            scrollPadding: EdgeInsets.symmetric(
                                                vertical: MediaQuery.of(context)
                                                    .viewInsets
                                                    .bottom),
                                            keyboardType: TextInputType.text,
                                            controller: _noteEditingController,
                                            decoration: InputDecoration(
                                              labelText: 'Add notes (optional)',
                                              hintText: 'Add notes (optional)',
                                              isDense: true,
                                              enabledBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                    color: Colors.grey),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              focusedBorder: OutlineInputBorder(
                                                borderSide: const BorderSide(
                                                  color: Colors.black,
                                                  width: 1,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else if (!snapshot.hasData) {
                                    return const Center(
                                      child: Text('Internal Server Error'),
                                    );
                                  }

                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                }))
                          ],
                        ))
                  ],
                ),
              ),
            ),
            SizedBox(
                child: Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      ValueListenableBuilder(
                          valueListenable: _editingTotal,
                          builder: (context, value, child) {
                            return IconButton(
                                onPressed:
                                    value.text.isNotEmpty && value.text != '0'
                                        ? _decrementPackTotal
                                        : null,
                                icon: const Icon(Icons.remove));
                          }),
                      SizedBox(
                        width: 70,
                        child: TextField(
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          controller: _editingTotal,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.all(6),
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(color: Colors.grey),
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
                        ),
                      ),
                      IconButton(
                          onPressed: () {
                            _incrementPackTotal();
                          },
                          icon: const Icon(Icons.add)),
                    ],
                  ),
                  Expanded(
                      child: (int.parse(_editingTotal.text) == 0 &&
                              itemCart.isNotEmpty)
                          ? ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors
                                      .white, //change background color of button
                                  backgroundColor: const Color(0xffFF453A)),
                              onPressed: isSubmitting
                                  ? null
                                  : () {
                                      handleDeleteCart().then((value) {
                                        setState(() {
                                          isSubmitting = false;
                                        });
                                        Color snackbarColor =
                                            const Color(0xff22762C);
                                        String snackbarText =
                                            'Item successfully deleted';
                                        if (value == null) {
                                          snackbarColor =
                                              const Color(0xffFF453A);
                                          snackbarText =
                                              'Failed to delete item';
                                        }

                                        final snackBar = SnackBar(
                                          width: MediaQuery.of(context)
                                                  .size
                                                  .width *
                                              0.5,
                                          behavior: SnackBarBehavior.floating,
                                          backgroundColor: snackbarColor,
                                          content:
                                              Center(child: Text(snackbarText)),
                                        );

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(snackBar);

                                        if (value != null) {
                                          getCartList().then((value) {
                                            Scaffold.of(context)
                                                .closeEndDrawer();
                                          });
                                        }
                                      });
                                    },
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 15,
                                      width: 15,
                                      child: CircularProgressIndicator(),
                                    )
                                  : Text('Remove From Your Cart',
                                      style: TextStyle(fontSize: 16.sp)))
                          : ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors
                                      .white, //change background color of button
                                  backgroundColor:
                                      Theme.of(context).primaryColor),
                              onPressed: int.parse(_editingTotal.text) > 0 &&
                                      !isSubmitting
                                  ? handlePressButton
                                  : null,
                              child: isSubmitting
                                  ? const SizedBox(
                                      height: 15,
                                      width: 15,
                                      child: CircularProgressIndicator(),
                                    )
                                  : Text(
                                      itemCart.isNotEmpty
                                          ? 'Update cart - ${CurrencyFormat.convertToIdr(totalMenuPrice + totalModifierPrice, 0)}'
                                          : 'Add to cart - ${CurrencyFormat.convertToIdr(totalMenuPrice + totalModifierPrice, 0)}',
                                      style: TextStyle(fontSize: 16.sp))))
                ],
              ),
            ))
          ],
        )),
      );
    });
  }
}
