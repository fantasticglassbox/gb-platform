import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:glassbox/component/bill_status_badge.dart';
import 'package:glassbox/utils/currency.dart';
import 'package:intl/intl.dart';

class BillDrawer extends StatefulWidget {
  final Map billItem;
  final String billDate;
  const BillDrawer({super.key, required this.billItem, required this.billDate});

  @override
  State<BillDrawer> createState() => _BillDrawerState();
}

Widget getIconStatus(String status) {
  IconData statusIcon = FontAwesomeIcons.clock;
  Color statusColorIcon = const Color(0xffEEA23E);

  if (status == 'CANCEL') {
    statusIcon = FontAwesomeIcons.circleXmark;
    statusColorIcon = const Color(0xffFF453A);
  } else if (status == 'PENDING' || status == 'PREPARING') {
    statusIcon = FontAwesomeIcons.circleHalfStroke;
    statusColorIcon = const Color(0xff4D9CFF);
  } else if (status == 'COMPLETED') {
    statusIcon = FontAwesomeIcons.circleCheck;
    statusColorIcon = const Color(0xff2AA63C);
  }

  if (status == 'PENDING') {
    return const FaIcon(
      FontAwesomeIcons.clock,
      size: 60.0,
      color: Color(0xffEEA23E),
    );
  }

  return FaIcon(
    statusIcon,
    size: 60.0,
    color: statusColorIcon,
  );
}

String getOrderTime(String dateString) {
  DateTime dateTime = DateTime.parse(dateString);
  String formattedDate = DateFormat.yMMMEd().format(dateTime);
  return formattedDate;
}

String renderModifiers(Map modifers, String note) {
  String modifiers = '';
  for (var item in modifers.keys) {
    List names = [];
    for (var i = 0; i < modifers[item].length; i++) {
      names.add(modifers[item][i]['name']);
    }
    String values = names.join(', ');
    modifiers += '$item: $values, ';
  }

  modifiers += 'note: $note';

  return modifiers;
}

class _BillDrawerState extends State<BillDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: MediaQuery.of(context).size.width * 0.4,
      child: Column(
        children: [
          Expanded(
            flex: 1,
            child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                    bottom: 16.0, left: 16.0, right: 16.0, top: 16.0),
                child: Column(
                  children: [
                    Center(
                      child: Text(
                        'Order ${widget.billItem['short_id']}',
                        style: TextStyle(fontSize: 22.sp),
                      ),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Center(
                      child: getIconStatus(widget.billItem['status']),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Status',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        BillStatusBadge(status: widget.billItem['status']),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Time',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        Text(
                          getOrderTime(widget.billDate),
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16.sp),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Items',
                          style: TextStyle(fontSize: 16.sp),
                        ),
                        Text(
                          '${widget.billItem['items'].length}',
                          style: TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 16.sp),
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 5,
                    ),
                    const Divider(
                      height: 30,
                    ),
                    ...widget.billItem['items'].map((item) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          SizedBox(
                            width: 20,
                            child: Text(
                              '${item['quantity']}',
                              style: TextStyle(fontSize: 16.sp),
                            ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${item['name']}',
                                  style: TextStyle(fontSize: 16.sp),
                                ),
                                Text(
                                  renderModifiers(
                                      item['modifiers'], item['note']),
                                  style: TextStyle(
                                      color: const Color(0xff979AA0),
                                      fontSize: 14.sp),
                                )
                              ],
                            ),
                          ),
                          Text(
                            CurrencyFormat.convertToIdr(
                                item['price']['value'], 0),
                            style: TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 16.sp),
                          ),
                        ],
                      );
                    })
                  ],
                )),
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Subtotal',
                  style: TextStyle(fontSize: 20.sp),
                ),
                Text(
                  CurrencyFormat.convertToIdr(
                      widget.billItem['total']['value'], 0),
                  style:
                      TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w600),
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
