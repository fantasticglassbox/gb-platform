import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassbox/utils/icon.dart';

class GuidelineDrawer extends StatefulWidget {
  const GuidelineDrawer({super.key});

  @override
  State<GuidelineDrawer> createState() => _GuidelineDrawerState();
}

class _GuidelineDrawerState extends State<GuidelineDrawer> {
  Widget _renderCard(
      String iconString, String categoryName, String description) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            GBIcon.getIcon(iconString, size: 20.sp),
            const SizedBox(
              height: 10,
            ),
            Text(
              categoryName,
              style: TextStyle(fontSize: 16.sp),
            ),
            Text(
              description,
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12.sp),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      double widthFactor = 0.4;
      double aspectRatio2 = 1.6;
      double aspectRatio4 = 0.75;
      int gridCount = 3;
      if (width <= 700) {
        widthFactor = 0.5;
        aspectRatio2 = 1.4;
        aspectRatio4 = 1.4;
        gridCount = 2;
      }
      return Drawer(
        width: MediaQuery.of(context).size.width * widthFactor,
        child: SafeArea(
            child: Container(
          padding: EdgeInsets.all(16.0),
          child: ListView(
            children: [
              Text(
                'Menu Guideline',
                style: TextStyle(fontSize: 20.sp),
              ),
              const SizedBox(
                height: 20.0,
              ),
              Text(
                'Featured Selections',
                style: TextStyle(fontSize: 18.sp),
              ),
              const SizedBox(
                height: 10.0,
              ),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                childAspectRatio: aspectRatio2,
                primary: false,
                children: [
                  _renderCard('special-offers', 'Special Offers',
                      'Discounted delights await! Explore now'),
                  _renderCard('recommended', 'Recommended',
                      'Savory selections by our expert'),
                  _renderCard('trending', 'Trending',
                      'Most popular dishes loved by all'),
                  _renderCard(
                      'new', 'New', 'Fresh flavors, culinary innovation'),
                ],
              ),
              const SizedBox(
                height: 20.0,
              ),
              Text(
                'Menu Guideline',
                style: TextStyle(fontSize: 20.sp),
              ),
              const SizedBox(
                height: 20.0,
              ),
              Text(
                'Featured Selections',
                style: TextStyle(fontSize: 18.sp),
              ),
              const SizedBox(
                height: 10.0,
              ),
              GridView.count(
                crossAxisCount: gridCount,
                shrinkWrap: true,
                childAspectRatio: aspectRatio4,
                primary: false,
                children: [
                  _renderCard('chili', 'Special Offers',
                      'Utilizes ingredients like chili peppers, jalapeños, or hot sauces to add heat and flavor'),
                  _renderCard('shrimp', 'Recommended',
                      'Savory selections by our expert'),
                  _renderCard(
                      'sugar', 'Trending', 'Most popular dishes loved by all'),
                  _renderCard(
                      'new', 'New', 'Fresh flavors, culinary innovation'),
                ],
              ),
            ],
          ),
        )),
      );
    });
  }
}
