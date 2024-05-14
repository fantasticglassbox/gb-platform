import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class BillStatusBadge extends StatelessWidget {
  final String status;
  const BillStatusBadge({super.key, required this.status});

  String getTextTitle(String status) {
    String textTitle = 'Submitted';
    if (status == 'CANCEL') {
      textTitle = 'Cancelled';
    } else if (status == 'PENDING' || status == 'PREPARING') {
      textTitle = 'In Progress';
    } else if (status == 'COMPLETED') {
      textTitle = 'Completed';
    }

    return textTitle;
  }

  List<Color> getBadgeColor(String status) {
    List<Color> colors = [Color(0xffEEA23E), Color(0xffFDEFDC)];
    if (status == 'CANCEL') {
      colors = [Color(0xffFF453A), Color(0xffFDDDDC)];
    } else if (status == 'PENDING' || status == 'PREPARING') {
      colors = [Color(0xff4D9CFF), Color(0xffD3E7FF)];
    } else if (status == 'COMPLETED') {
      colors = [Color(0xff2AA63C), Color(0xffD4F4D8)];
    }

    return colors;
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      getTextTitle(status),
      style: TextStyle(
          fontSize: 14.sp,
          color: getBadgeColor(status)[0],
          backgroundColor: getBadgeColor(status)[1]),
    );
  }
}
