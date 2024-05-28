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
  Widget renderImage(String imageUrl) {
    if (imageUrl.isEmpty) {
      String imageName = '';

      if (widget.textIcon == 'trending') {
        imageName = 'images/default-trending.jpg';
      } else if (widget.textIcon == 'new') {
        imageName = 'images/default-new.jpg';
      } else if (widget.textIcon == 'recommended') {
        imageName = 'images/default-recommended.jpg';
      } else if (widget.textIcon == 'special-offers') {
        imageName = 'images/default-special-offers.jpg';
      }

      return Image.asset(imageName,
          width: double.infinity, height: 133.sp, fit: BoxFit.cover);
    } else {
      return Image.network(
          width: double.infinity, height: 133.sp, fit: BoxFit.cover, imageUrl);
    }
  }

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
            renderImage(widget.imageUrl),
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
