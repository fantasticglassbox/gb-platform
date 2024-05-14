import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassbox/providers/app.dart';
import 'package:glassbox/providers/menu.dart';
import 'package:glassbox/utils/currency.dart';
import 'package:glassbox/utils/icon.dart';
import 'package:provider/provider.dart';

class MenuCard extends StatefulWidget {
  final Map<String, dynamic> menu;
  final bool showAsGrid;
  const MenuCard({super.key, required this.menu, this.showAsGrid = false});

  @override
  State<MenuCard> createState() => _MenuCardState();
}

class _MenuCardState extends State<MenuCard> {
  void getMenuModifier() {
    Map activeMenu = {
      'menuId': widget.menu['id'],
      'menuName': widget.menu['name'],
      'menuImage': widget.menu['image'],
      'menuDescription': widget.menu['description'],
      'menuPrice': widget.menu['price'],
      'menuDiscount': widget.menu['discount'],
      'menuCategories': widget.menu['categories'],
      'menuPriceAfterDiscount': widget.menu['price_after_discount'],
    };
    context.read<MenuProvider>().setActiveMenu(activeMenu);
    context.read<AppProvider>().setIsMenuDrawer(true);
    Scaffold.of(context).openEndDrawer();
  }

  Widget renderMenuLabelIcons(String labels) {
    final iconStrings = labels.split(',');
    return Row(
      children: iconStrings.map((item) {
        return SizedBox(
          width: 15,
          child: GBIcon.getIcon(item, size: 10.0),
        );
      }).toList(),
    );
  }

  List<Widget> renderCategoryIcon(List categories, {double size = 16}) {
    return categories.map((item) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GBIcon.getIcon(item['icon'], size: size),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: () {
              getMenuModifier();
            },
            child: widget.showAsGrid
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                        Stack(
                          children: [
                            Image.network(
                                // 'https://gbstorage.sgp1.digitaloceanspaces.com/assets/dev/a/f89c0d84ed1db2e3.png',
                                widget.menu['image'] != ''
                                    ? widget.menu['image']
                                    : 'https://placehold.co/200/png',
                                width: double.infinity,
                                height: widget.menu['imageSize'],
                                fit: BoxFit.cover),
                            Positioned(
                                right: 10,
                                top: 10,
                                child: Container(
                                  decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      color: Colors.white,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.white,
                                            spreadRadius: 3)
                                      ]),
                                  child: Row(
                                    children: [
                                      ...renderCategoryIcon(
                                          widget.menu['categories']),
                                    ],
                                  ),
                                ))
                          ],
                        ),
                        Expanded(
                            child: Stack(
                          children: [
                            Container(
                                padding: const EdgeInsets.all(8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    widget.menu['discount'] != 0
                                        ? Row(
                                            children: [
                                              Text(
                                                CurrencyFormat.convertToIdr(
                                                    widget.menu['price'], 0),
                                                style: TextStyle(
                                                    fontSize: 12.sp,
                                                    decoration: TextDecoration
                                                        .lineThrough),
                                              ),
                                              const SizedBox(
                                                width: 10.0,
                                              ),
                                              Text(
                                                '-${widget.menu['discount']}%',
                                                style: TextStyle(
                                                    fontSize: 8.sp,
                                                    color: Color(0xffEEA23E),
                                                    backgroundColor:
                                                        Color(0xffFDEFDC)),
                                              )
                                            ],
                                          )
                                        : SizedBox(),
                                    Text(
                                      widget.menu['discount'] == 0
                                          ? CurrencyFormat.convertToIdr(
                                              widget.menu['price'], 0)
                                          : CurrencyFormat.convertToIdr(
                                              widget
                                                  .menu['price_after_discount'],
                                              0),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.sp),
                                    ),
                                    Text(
                                      widget.menu['name'],
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w500),
                                    ),
                                    Text(widget.menu['description'],
                                        maxLines: 3,
                                        style: TextStyle(fontSize: 12.sp),
                                        overflow: TextOverflow.ellipsis),
                                  ],
                                )),
                            Positioned(
                              left: 8,
                              bottom: 8,
                              child:
                                  renderMenuLabelIcons(widget.menu['labels']),
                            )
                          ],
                        ))
                      ])
                : Row(
                    children: [
                      Stack(
                        children: [
                          Image.network(
                              // 'https://gbstorage.sgp1.digitaloceanspaces.com/assets/dev/a/f89c0d84ed1db2e3.png',
                              widget.menu['image'] != ''
                                  ? widget.menu['image']
                                  : 'https://placehold.co/200/png',
                              width: 108,
                              height: double.infinity,
                              fit: BoxFit.cover),
                          Positioned(
                              left: 10,
                              bottom: 10,
                              child: Container(
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(20),
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.white, spreadRadius: 3)
                                    ]),
                                child: Row(
                                  children: [
                                    ...renderCategoryIcon(
                                        widget.menu['categories'],
                                        size: 10),
                                  ],
                                ),
                              ))
                        ],
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Expanded(
                          child: Stack(
                        children: [
                          Container(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  widget.menu['discount'] != 0
                                      ? Row(
                                          children: [
                                            Text(
                                              CurrencyFormat.convertToIdr(
                                                  widget.menu['price'], 0),
                                              style: TextStyle(
                                                  fontSize: 12.sp,
                                                  decoration: TextDecoration
                                                      .lineThrough),
                                            ),
                                            SizedBox(
                                              width: 10.0,
                                            ),
                                            Text(
                                              '-${widget.menu['discount']}%',
                                              style: TextStyle(
                                                  fontSize: 8.sp,
                                                  color: Color(0xffEEA23E),
                                                  backgroundColor:
                                                      Color(0xffFDEFDC)),
                                            )
                                          ],
                                        )
                                      : SizedBox(),
                                  Text(
                                    widget.menu['discount'] == 0
                                        ? CurrencyFormat.convertToIdr(
                                            widget.menu['price'], 0)
                                        : CurrencyFormat.convertToIdr(
                                            widget.menu['price_after_discount'],
                                            0),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.sp),
                                  ),
                                  Text(
                                    widget.menu['name'],
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 16.sp,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    widget.menu['description'],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(fontSize: 12.sp),
                                  )
                                ],
                              )),
                          Positioned(
                            left: 8,
                            bottom: 8,
                            child: renderMenuLabelIcons(widget.menu['labels']),
                          )
                        ],
                      ))
                    ],
                  )));
  }
}
