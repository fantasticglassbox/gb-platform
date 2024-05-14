import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassbox/providers/app.dart';
import 'package:glassbox/utils/icon.dart';
import 'package:provider/provider.dart';

class CategoryCard extends StatefulWidget {
  final int index;
  final String text;
  final String imageUrl;
  final String textIcon;

  const CategoryCard(
      {super.key,
      required this.index,
      required this.text,
      required this.imageUrl,
      required this.textIcon});

  @override
  _CategoryCardState createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  @override
  Widget build(BuildContext context) {
    return Card(
        elevation: 5.0,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            context.read<AppProvider>().setTabPosition(widget.index + 1);
            context.read<AppProvider>().setActiveNavigationRailIndex(1);
          },
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Image.network(
                width: double.infinity,
                height: 133.sp,
                fit: BoxFit.cover,
                widget.imageUrl),
            Container(
              padding: const EdgeInsets.all(8.0),
              child: Row(children: [
                GBIcon.getIcon(widget.textIcon),
                const SizedBox(width: 8),
                Text(
                  widget.text,
                  style: TextStyle(fontSize: 12.sp),
                )
              ]),
            )
          ]),
        ));
  }
}
