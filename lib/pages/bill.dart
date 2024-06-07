import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:glassbox/component/bill_drawer.dart';
import 'package:glassbox/component/bill_status_badge.dart';
import 'package:glassbox/providers/app.dart';
import 'package:glassbox/providers/merchant.dart';
import 'package:glassbox/utils/currency.dart';
import 'package:glassbox/utils/shared_preference.dart';
import 'package:idle_detector_wrapper/idle_detector_wrapper.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;

class BillPage extends StatefulWidget {
  const BillPage({super.key});

  @override
  State<BillPage> createState() => _BillPageState();
}

class _BillPageState extends State<BillPage> {
  final _storage = const FlutterSecureStorage();
  late Future futureBill;
  final _formKey = GlobalKey<FormBuilderState>();
  late TextEditingController _emailTextController;

  Map selectedItemBill = {};
  String billDate = DateTime.now().toString();
  bool isClosingBill = false;
  bool isBillHasPendingOrder = false;
  bool isBillHasOnlyOneOrder = false;
  String billId = '';
  int totalPack = 0;

  Future readDataFromLocal() async {
    final storage = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );
    String? _totalPack = storage['total_pack'];
    if (_totalPack != null) {
      setState(() {
        totalPack = int.parse(_totalPack);
      });
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    readDataFromLocal();
    futureBill = getBill().then((value) {
      if (value != null) {
        for (var i = 0; i < value['orders'].length; i++) {
          if (value['orders'][i]['status'] == 'SUBMITTED' ||
              value['orders'][i]['status'] == 'PREPARING' ||
              value['orders'][i]['status'] == 'PENDING') {
            setState(() {
              isBillHasPendingOrder = true;
            });
            break;
          }
        }

        if (value['orders'].length == 1 &&
            value['orders'][0]['status'] == 'SUBMITTED') {
          setState(() {
            isBillHasOnlyOneOrder = true;
          });
        }

        setState(() {
          billId = value['id'];
        });
      }
      return value;
    });
    _emailTextController = TextEditingController();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    _emailTextController.dispose();
  }

  Future closeBill() async {
    var url = Uri.https('api.glassbox.id', '/v1/bills/close');
    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );
    final response = await http.post(url,
        headers: {'Authorization': 'Bearer ${token['access_token']}'});

    final Map responseBody = json.decode(response.body);

    return responseBody;
  }

  Future<Map> sendEmail() async {
    var url = Uri.https('api.glassbox.id', '/v1/bills/email');
    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );
    final response = await http.post(url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${token['access_token']}'
        },
        body: json
            .encode({'email': _emailTextController.text, 'bill_id': billId}));

    final Map responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      return responseBody;
    } else {
      throw Exception('Failed to load current cart list');
    }
  }

  Future getBill() async {
    var url = Uri.https('api.glassbox.id', '/v1/bills/current');
    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );
    final response = await http.get(url,
        headers: {'Authorization': 'Bearer ${token['access_token']}'});

    final Map responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      return responseBody;
    } else if (response.statusCode == 404) {
      return null;
    } else {
      throw Exception('Failed to load current bill');
    }
  }

  void closeDialog() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  refreshPage() {
    setState(() {
      futureBill = getBill();
    });
  }

  Future<String?> openEmailDialog() => showDialog<String>(
      // barrierDismissible: false,
      context: context,
      builder: (context) {
        return AlertDialog(
          surfaceTintColor: Colors.white,
          title: Center(
            child:
                Text('Provide your email', style: TextStyle(fontSize: 16.sp)),
          ),
          content: SizedBox(
              width: 150.0,
              child: FormBuilder(
                key: _formKey,
                clearValueOnUnregister: true,
                child: FormBuilderTextField(
                  style: TextStyle(fontSize: 16.sp),
                  name: 'bill_email',
                  controller: _emailTextController,
                  keyboardType: TextInputType.emailAddress,
                  validator: FormBuilderValidators.compose([
                    FormBuilderValidators.required(),
                    FormBuilderValidators.email()
                  ]),
                  decoration: InputDecoration(
                      hintText: 'Email address',
                      isDense: true,
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
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.grey),
                        borderRadius: BorderRadius.circular(10),
                      )),
                ),
              )),
          actions: [
            Row(
              children: [
                Expanded(
                    child: ElevatedButton(
                        onPressed: () {
                          closeDialog();
                        },
                        child: Text(
                          'Cancel',
                          style: TextStyle(fontSize: 16.sp),
                        ))),
                const SizedBox(
                  width: 10,
                ),
                StatefulBuilder(builder: (context, setState) {
                  return Expanded(
                      child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              foregroundColor: Colors
                                  .white, //change background color of button
                              backgroundColor: Theme.of(context).primaryColor),
                          onPressed: isClosingBill
                              ? null
                              : () async {
                                  if (_formKey.currentState!
                                      .saveAndValidate()) {
                                    setState(() {
                                      isClosingBill = true;
                                    });
                                    await sendEmail().then((value) {
                                      setState(() {
                                        isClosingBill = false;
                                      });
                                      final snackBar = SnackBar(
                                        width:
                                            MediaQuery.of(context).size.width *
                                                0.5,
                                        behavior: SnackBarBehavior.floating,
                                        backgroundColor:
                                            const Color(0xff22762C),
                                        content: Center(
                                            child: Text(
                                                'Successfully sent to your email',
                                                style: TextStyle(
                                                    fontSize: 16.sp))),
                                      );
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(snackBar);
                                      closeDialog();
                                    });
                                  }
                                },
                          child: isClosingBill
                              ? const SizedBox(
                                  height: 15,
                                  width: 15,
                                  child: CircularProgressIndicator(),
                                )
                              : Text('Send',
                                  style: TextStyle(fontSize: 16.sp))));
                }),
              ],
            )
          ],
        );
      });

  Future<String?> openDialog() => showDialog<String>(
      // barrierDismissible: false,
      context: context,
      builder: (context) {
        String message =
            "After tapping 'Close the Bill' below, you'll immediately finalize the bill. Our staff will handle the payment shortly.";
        if (isBillHasOnlyOneOrder) {
          message =
              "You've submitted your order(s). Kindly wait for the kitchen to prepare them. Closing the bill will result in no bill being generated.";
        } else if (isBillHasPendingOrder) {
          message =
              "Please wait until all orders have a status of 'Completed' before closing the bill, as there is currently at least one order in progress, indicating that the kitchen is preparing it.";
        }
        return AlertDialog(
          surfaceTintColor: Colors.white,
          title: Center(
            child: Text('Close Bill?', style: TextStyle(fontSize: 16.sp)),
          ),
          content: SizedBox(
              width: 150.0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16.sp)),
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
                        child:
                            Text('Cancel', style: TextStyle(fontSize: 16.sp)))),
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
                              backgroundColor: Theme.of(context).primaryColor),
                          onPressed: isClosingBill
                              ? null
                              : () async {
                                  setState(() {
                                    isClosingBill = true;
                                  });
                                  await closeBill().then((value) {
                                    setState(() {
                                      isClosingBill = false;
                                    });
                                    Color snackbarColor =
                                        const Color(0xff22762C);
                                    String snackbarText =
                                        'Bill successfully closed';
                                    if (value.containsKey('error')) {
                                      snackbarColor = const Color(0xffFF453A);
                                      snackbarText = value['error'];
                                    }
                                    final snackBar = SnackBar(
                                      width: MediaQuery.of(context).size.width *
                                          0.5,
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor: snackbarColor,
                                      content: Center(
                                          child: Text(snackbarText,
                                              style:
                                                  TextStyle(fontSize: 16.sp))),
                                    );
                                    ScaffoldMessenger.of(context)
                                        .showSnackBar(snackBar);
                                    closeDialog();

                                    if (!value.containsKey('error')) {
                                      refreshPage();
                                    }
                                  });
                                },
                          child: isClosingBill
                              ? const SizedBox(
                                  height: 15,
                                  width: 15,
                                  child: CircularProgressIndicator(),
                                )
                              : Text('Close Bill',
                                  style: TextStyle(fontSize: 16.sp))));
                })
              ],
            )
          ],
        );
      });

  Future<String?> openNotificationPendingOrderDialog() => showDialog<String>(
      // barrierDismissible: false,
      context: context,
      builder: (context) => AlertDialog(
            surfaceTintColor: Colors.white,
            title: Center(
              child:
                  Text('Pending Order(s)', style: TextStyle(fontSize: 16.sp)),
            ),
            content: SizedBox(
                width: 150.0,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                        "There is at least one order with the status “Submitted” or “In Progress”. Please wait until all statuses change to “Completed” before closing the bill.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16.sp)),
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
                          style: ElevatedButton.styleFrom(
                              foregroundColor: Colors
                                  .white, //change background color of button
                              backgroundColor: Theme.of(context).primaryColor),
                          onPressed: () {
                            closeDialog();
                          },
                          child:
                              Text('OK', style: TextStyle(fontSize: 16.sp)))),
                ],
              )
            ],
          ));

  List<Widget> renderBottomNavButton(bool closedBill) {
    if (closedBill) {
      return [
        ElevatedButton(
            style: ElevatedButton.styleFrom(
                foregroundColor:
                    Colors.white, //change background color of button
                backgroundColor: Theme.of(context).primaryColor),
            onPressed: () {
              openEmailDialog();
            },
            child:
                Text('Send to your email', style: TextStyle(fontSize: 16.sp)))
      ];
    }

    return [
      ElevatedButton(
        style: ElevatedButton.styleFrom(
            foregroundColor: Theme.of(context)
                .primaryColor, //change background color of button
            backgroundColor: const Color.fromRGBO(234, 244, 252, 1)),
        onPressed: () {
          context.read<AppProvider>().setActiveNavigationRailIndex(1);
          Navigator.pushNamed(context, '/main');
        },
        child: Text('Add More', style: TextStyle(fontSize: 16.sp)),
      ),
      const SizedBox(
        width: 20,
      ),
      ElevatedButton(
          style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, //change background color of button
              backgroundColor: Theme.of(context).primaryColor),
          onPressed: () {
            openDialog();
          },
          child: Text('Close Bill', style: TextStyle(fontSize: 16.sp)))
    ];
  }

  String getOrderTime(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    String formattedDate = DateFormat.yMMMEd().format(dateTime);
    return formattedDate;
  }

  String renderModifiers(Map modifers, String note) {
    String modifiers = '';
    for (var item in modifers.keys) {
      List values = modifers[item].map((modifers) => modifers['name']).toList();
      modifiers += '$item: ${values.join(', ')}, ';
    }

    if (note.isNotEmpty) {
      modifiers += 'note: $note';
    }

    return modifiers;
  }

  List<Widget> renderOrderItems(List orders) {
    return orders.map((item) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          'Order ID ${item['short_id']}',
          style: TextStyle(fontSize: 16.sp),
        ),
        const SizedBox(
          height: 10,
        ),
        ...item['items'].map((order) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 20,
                child: Text('${order['quantity']}',
                    style: TextStyle(fontSize: 16.sp)),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${order['name']}', style: TextStyle(fontSize: 16.sp)),
                    Text(
                      renderModifiers(order['modifiers'], order['note']),
                      style:
                          TextStyle(color: Color(0xff979AA0), fontSize: 10.sp),
                    )
                  ],
                ),
              ),
              Text(
                CurrencyFormat.convertToIdr(order['price']['value'], 0),
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16.sp),
              ),
            ],
          );
        }),
        const Divider(
          height: 20,
        )
      ]);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Your Bill'),
        centerTitle: true,
        surfaceTintColor: Colors.white,
        actions: [Container()],
      ),
      endDrawer: BillDrawer(
        billItem: selectedItemBill,
        billDate: billDate,
      ),
      body: SafeArea(
          child: Container(
              height: double.infinity,
              width: double.infinity,
              padding:
                  const EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0),
              color: const Color.fromRGBO(247, 247, 247, 1.0),
              child: FutureBuilder(
                  future: futureBill,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      final data = snapshot.data;
                      if (data['status'] == 'CLOSED') {
                        return SingleChildScrollView(
                          child: Center(
                              child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: Column(
                              children: [
                                Card(
                                  surfaceTintColor: Colors.white,
                                  color: Colors.white,
                                  clipBehavior: Clip.antiAlias,
                                  child: Container(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Center(
                                              child: CircleAvatar(
                                            radius: 24,
                                            backgroundImage: NetworkImage(
                                                context
                                                    .watch<MerchantProvider>()
                                                    .logoImage),
                                          )),
                                          const SizedBox(
                                            height: 30,
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Bill ID',
                                                  style: TextStyle(
                                                      fontSize: 16.sp)),
                                              Text(data?['id'],
                                                  style: TextStyle(
                                                      fontSize: 16.sp)),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Date',
                                                  style: TextStyle(
                                                      fontSize: 16.sp)),
                                              Text(
                                                  getOrderTime(
                                                      data?['created_at']),
                                                  style: TextStyle(
                                                      fontSize: 16.sp))
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Table ID',
                                                  style: TextStyle(
                                                      fontSize: 16.sp)),
                                              Text(data?['table_no'],
                                                  style: TextStyle(
                                                      fontSize: 16.sp))
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('PAX',
                                                  style: TextStyle(
                                                      fontSize: 16.sp)),
                                              Text('$totalPack',
                                                  style: TextStyle(
                                                      fontSize: 16.sp))
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          const Divider(
                                            height: 20,
                                          ),
                                          ...renderOrderItems(data?['orders']),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Total',
                                                  style: TextStyle(
                                                      fontSize: 16.sp)),
                                              Text(
                                                  CurrencyFormat.convertToIdr(
                                                      data?['total']['value'],
                                                      0),
                                                  style: TextStyle(
                                                      fontSize: 16.sp))
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Service Charge',
                                                  style: TextStyle(
                                                      fontSize: 16.sp)),
                                              Text(
                                                  CurrencyFormat.convertToIdr(
                                                      data?['service_fee']
                                                          ['value'],
                                                      0),
                                                  style: TextStyle(
                                                      fontSize: 16.sp))
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('VAT',
                                                  style: TextStyle(
                                                      fontSize: 16.sp)),
                                              Text(
                                                  CurrencyFormat.convertToIdr(
                                                      data?['vat']['value'], 0),
                                                  style: TextStyle(
                                                      fontSize: 16.sp))
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('PB1',
                                                  style: TextStyle(
                                                      fontSize: 16.sp)),
                                              Text(
                                                  CurrencyFormat.convertToIdr(
                                                      data?['pb1']['value'], 0),
                                                  style: TextStyle(
                                                      fontSize: 16.sp))
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          const Divider(
                                            height: 20,
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Grand Total',
                                                style:
                                                    TextStyle(fontSize: 20.sp),
                                              ),
                                              Text(
                                                CurrencyFormat.convertToIdr(
                                                    data?['grand_total']
                                                        ['value'],
                                                    0),
                                                style: TextStyle(
                                                    fontSize: 20.sp,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              )
                                            ],
                                          ),
                                        ],
                                      )),
                                )
                              ],
                            ),
                          )),
                        );
                      } else {
                        return SingleChildScrollView(
                          child: Center(
                              child: SizedBox(
                            width: MediaQuery.of(context).size.width * 0.7,
                            child: Column(
                              children: [
                                ...data?['orders'].map((item) {
                                  return Card(
                                      surfaceTintColor: Colors.white,
                                      color: Colors.white,
                                      clipBehavior: Clip.antiAlias,
                                      child: Builder(builder: (context) {
                                        return InkWell(
                                          onTap: () {
                                            setState(() {
                                              selectedItemBill = item;
                                              billDate = data['created_at'];
                                            });
                                            Scaffold.of(context)
                                                .openEndDrawer();
                                          },
                                          child: Container(
                                              padding:
                                                  const EdgeInsets.all(16.0),
                                              child: Column(
                                                children: [
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          BillStatusBadge(
                                                              status: item[
                                                                  'status']),
                                                          const SizedBox(
                                                            height: 5,
                                                          ),
                                                          Text(
                                                            'Order ${item['short_id']}',
                                                            style: TextStyle(
                                                                fontSize:
                                                                    20.sp),
                                                          ),
                                                        ],
                                                      ),
                                                      const Column(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .start,
                                                        children: [
                                                          FaIcon(
                                                            FontAwesomeIcons
                                                                .arrowRight,
                                                            size: 18.0,
                                                            color: Color(
                                                                0xffA1A4AC),
                                                          ),
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                  const SizedBox(
                                                    height: 10,
                                                  ),
                                                  Row(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .spaceBetween,
                                                    children: [
                                                      Text(
                                                          'Total ${item['items'].length} items',
                                                          style: TextStyle(
                                                              fontSize: 16.sp)),
                                                      Text(
                                                          CurrencyFormat
                                                              .convertToIdr(
                                                                  item['total']
                                                                      ['value'],
                                                                  0),
                                                          style: TextStyle(
                                                              fontSize: 16.sp))
                                                    ],
                                                  )
                                                ],
                                              )),
                                        );
                                      }));
                                }).toList(),
                                Card(
                                  surfaceTintColor: Colors.white,
                                  color: Colors.white,
                                  clipBehavior: Clip.antiAlias,
                                  child: Container(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Column(
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Total',
                                                  style: TextStyle(
                                                      fontSize: 16.sp)),
                                              Text(
                                                  CurrencyFormat.convertToIdr(
                                                      data?['total']['value'],
                                                      0),
                                                  style: TextStyle(
                                                      fontSize: 16.sp))
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('Service Charge',
                                                  style: TextStyle(
                                                      fontSize: 16.sp)),
                                              Text(
                                                  CurrencyFormat.convertToIdr(
                                                      data?['service_fee']
                                                          ['value'],
                                                      0),
                                                  style: TextStyle(
                                                      fontSize: 16.sp))
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('VAT',
                                                  style: TextStyle(
                                                      fontSize: 16.sp)),
                                              Text(
                                                  CurrencyFormat.convertToIdr(
                                                      data?['vat']['value'], 0),
                                                  style: TextStyle(
                                                      fontSize: 16.sp))
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text('PB1',
                                                  style: TextStyle(
                                                      fontSize: 16.sp)),
                                              Text(
                                                  CurrencyFormat.convertToIdr(
                                                      data?['pb1']['value'], 0),
                                                  style: TextStyle(
                                                      fontSize: 16.sp))
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 10,
                                          ),
                                          const Divider(
                                            height: 20,
                                          ),
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                'Grand Total',
                                                style:
                                                    TextStyle(fontSize: 20.sp),
                                              ),
                                              Text(
                                                CurrencyFormat.convertToIdr(
                                                    data?['grand_total']
                                                        ['value'],
                                                    0),
                                                style: TextStyle(
                                                    fontSize: 20.sp,
                                                    fontWeight:
                                                        FontWeight.w600),
                                              )
                                            ],
                                          ),
                                        ],
                                      )),
                                )
                              ],
                            ),
                          )),
                        );
                      }
                    } else if (snapshot.hasError) {
                      return Text('Error ${snapshot.error}');
                    } else if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }

                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const FaIcon(
                            FontAwesomeIcons.receipt,
                            size: 60,
                          ),
                          const SizedBox(
                            height: 10,
                          ),
                          Text(
                              "Every time you checkout orders, they'll appear here.",
                              style: TextStyle(fontSize: 16.sp)),
                          const SizedBox(
                            height: 10,
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                foregroundColor: Colors
                                    .white, //change background color of button
                                backgroundColor:
                                    Theme.of(context).primaryColor),
                            onPressed: () {
                              context
                                  .read<AppProvider>()
                                  .setActiveNavigationRailIndex(1);
                              Navigator.pushNamed(context, '/main');
                            },
                            child: Text('Add More',
                                style: TextStyle(fontSize: 16.sp)),
                          ),
                        ],
                      ),
                    );
                  }))),
      bottomNavigationBar: FutureBuilder(
          future: futureBill,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              final data = snapshot.data;
              return Container(
                padding: const EdgeInsets.all(8.0),
                clipBehavior: Clip.antiAlias,
                decoration:
                    const BoxDecoration(color: Colors.white, boxShadow: [
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
                        child: Row(
                      children: [
                        Text('Grand Total', style: TextStyle(fontSize: 16.sp)),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          CurrencyFormat.convertToIdr(
                              data?['grand_total']['value'], 0),
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 20.sp),
                        ),
                      ],
                    )),
                    ...renderBottomNavButton(data['status'] == 'CLOSED')
                  ],
                ),
              );
            } else if (snapshot.hasError) {
              return Text('Error ${snapshot.error}');
            }

            return const SizedBox();
          }),
    );
  }
}
