import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glassbox/component/menu_card.dart';
import 'package:glassbox/model/menu.dart';
import 'package:glassbox/utils/icon.dart';
import 'package:glassbox/utils/shared_preference.dart';
import 'package:http/http.dart' as http;

class MenuCategory extends StatefulWidget {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  bool showAsGrid;
  double? imageSize;
  double? cardAspectRatio;
  List? menus;
  int crossAxisCount;
  MenuCategory(
      {super.key,
      required this.categoryId,
      required this.categoryName,
      required this.categoryIcon,
      this.showAsGrid = false,
      this.imageSize = 218,
      this.crossAxisCount = 4,
      this.menus,
      this.cardAspectRatio});

  @override
  State<MenuCategory> createState() => _MenuCategoryState();
}

class _MenuCategoryState extends State<MenuCategory> {
  final _storage = const FlutterSecureStorage();
  late Future<List<MenuModel>> futureMenu;

  Future<List<MenuModel>> getMenuList() async {
    var url = Uri.https(
        'api.glassbox.id', '/v1/menus', {'category_id': widget.categoryId});
    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );
    final response = await http.get(url,
        headers: {'Authorization': 'Bearer ${token['access_token']}'});

    final List responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      List<MenuModel> menuList =
          responseBody.map((e) => MenuModel.fromJSON(e)).toList();
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

  Widget renderCategoryWithMenu() {
    if (widget.menus != null) {
      return GridView.count(
        padding: const EdgeInsets.only(bottom: 20),
        mainAxisSpacing: 10.0,
        crossAxisSpacing: 10.0,
        primary: false,
        shrinkWrap: true,
        childAspectRatio: widget.cardAspectRatio ?? 1,
        crossAxisCount: widget.crossAxisCount,
        children: widget.menus!.map((item) {
          Map<String, dynamic> menuData = {
            "id": item['id'],
            "name": item['name'],
            "image": item['image'],
            "price": item['price'],
            "price_after_discount": item['price_after_discount'],
            "discount": item['discount'],
            "description": item['description'],
            "labels": item['labels'],
            "category_icon": widget.categoryIcon,
            "categories": item['categories'],
            "imageSize": widget.imageSize,
          };
          return MenuCard(
            menu: menuData,
            showAsGrid: widget.showAsGrid,
          );
        }).toList(),
      );
    } else {
      return FutureBuilder(
          future: futureMenu,
          builder: (context, snapshot) {
            if (snapshot.hasData && snapshot.data!.isNotEmpty) {
              final menuList = snapshot.data;
              return GridView.count(
                padding: const EdgeInsets.only(bottom: 20),
                mainAxisSpacing: 10.0,
                crossAxisSpacing: 10.0,
                primary: false,
                shrinkWrap: true,
                childAspectRatio: widget.cardAspectRatio ?? 1,
                crossAxisCount: widget.crossAxisCount,
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
                    "category_icon": widget.categoryIcon,
                    "categories": item.categories,
                    "imageSize": widget.imageSize,
                  };
                  return MenuCard(
                    menu: menuData,
                    showAsGrid: widget.showAsGrid,
                  );
                }).toList(),
              );
            } else if (snapshot.data != null && snapshot.data!.isEmpty) {
              return Center(
                  child: Text(
                'No menu for this category',
                style: TextStyle(fontSize: 20.sp),
              ));
            } else if (snapshot.hasError) {
              return Text('${snapshot.error}');
            }

            return const Center(child: CircularProgressIndicator());
          });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 10.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              GBIcon.getIcon(widget.categoryIcon, size: 25.0),
              SizedBox(width: 12),
              Text(
                widget.categoryName,
                style: TextStyle(color: Color(0xff525D6A), fontSize: 20.sp),
              )
            ]),
            // Text(
            //   'Optional description by retail here',
            //   style: TextStyle(color: Color(0xff979AA0)),
            // )
          ],
        ),
        const SizedBox(height: 10.0),
        renderCategoryWithMenu(),
      ],
    );
  }
}
