import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glassbox/component/menu_card.dart';
import 'package:glassbox/model/menu.dart';
import 'package:glassbox/utils/icon.dart';
import 'package:glassbox/utils/shared_preference.dart';
import 'package:http/http.dart' as http;

class AllCategory extends StatefulWidget {
  bool showAsGrid;
  double? cardAspectRatio;
  int crossAxisCount;
  AllCategory(
      {super.key,
      this.showAsGrid = false,
      this.crossAxisCount = 4,
      this.cardAspectRatio});

  @override
  State<AllCategory> createState() => _AllCategoryState();
}

class _AllCategoryState extends State<AllCategory> {
  final _storage = const FlutterSecureStorage();
  late Future<List> futureMenu;

  Future<List> getMenuList() async {
    var url = Uri.https('api.glassbox.id', '/v1/menus');
    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );
    final response = await http.get(url,
        headers: {'Authorization': 'Bearer ${token['access_token']}'});

    final List responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      List menuList = responseBody.map((e) => MenuModel.fromJSON(e)).toList();
      return menuList;
    } else {
      throw Exception('Failed to load menu list');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    futureMenu = getMenuList();
  }

  List normalizeMenuList(List? menus) {
    Map<String, dynamic> groupedMenuCategory = {};
    if (menus != null) {
      for (var element in menus) {
        for (var category in element.categories) {
          if (groupedMenuCategory.containsKey(category['name'])) {
            groupedMenuCategory[category['name']].add(element);
          } else {
            groupedMenuCategory[category['name']] = [];
          }
        }
      }
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: futureMenu,
        builder: (context, snapshot) {
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            final menuList = snapshot.data;
            List newMenuList = normalizeMenuList(menuList);
            return Column(
              children: [
                Column(
                  children: [
                    const SizedBox(height: 10.0),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          GBIcon.getIcon('sugar', size: 25.0),
                          const SizedBox(width: 12),
                          Text(
                            'All Menu',
                            style: TextStyle(
                                color: Color(0xff525D6A), fontSize: 20.sp),
                          )
                        ]),
                        // Text(
                        //   'Optional description by retail here',
                        //   style: TextStyle(color: Color(0xff979AA0)),
                        // )
                      ],
                    ),
                    const SizedBox(height: 10.0),
                    LayoutBuilder(builder: (context, constraints) {
                      final width = constraints.maxWidth;
                      double aspectRatio = 1;
                      int crossAxisCount = widget.crossAxisCount;
                      if (width > 636 && width <= 1280) {
                        if (widget.showAsGrid) {
                          aspectRatio = 0.65;
                        } else {
                          aspectRatio = 3.3;
                        }
                      } else if (width <= 636) {
                        if (widget.showAsGrid) {
                          aspectRatio = 0.8;
                          crossAxisCount = 2;
                        } else {
                          aspectRatio = 2.0;
                        }
                      }
                      return GridView.count(
                        padding: const EdgeInsets.only(bottom: 20),
                        mainAxisSpacing: 10.0,
                        crossAxisSpacing: 10.0,
                        primary: false,
                        shrinkWrap: true,
                        childAspectRatio: widget.cardAspectRatio ?? aspectRatio,
                        crossAxisCount: crossAxisCount,
                        children: menuList!.map((item) {
                          Map<String, dynamic> menuData = {
                            "id": item.id,
                            "name": item.name,
                            "image": item.image,
                            "price": item.price,
                            "price_after_discount": item.priceAfterDiscount,
                            "discount": item.discount,
                            "description": item.description,
                            "labels": item.labels,
                            "category_icon": 'sugar',
                            "categories": item.categories
                          };
                          return MenuCard(
                            menu: menuData,
                            showAsGrid: widget.showAsGrid,
                          );
                        }).toList(),
                      );
                    })
                  ],
                )
              ],
            );
          } else if (snapshot.data != null && snapshot.data!.isEmpty) {
            return Center(
                child: Text(
              'No menu for this category',
              style: TextStyle(fontSize: 22.sp),
            ));
          } else if (snapshot.hasError) {
            return Text('${snapshot.error}');
          }

          return const Center(child: CircularProgressIndicator());
        });
  }
}
