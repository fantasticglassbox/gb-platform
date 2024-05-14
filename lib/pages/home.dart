import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:glassbox/component/carousel.dart';
import 'package:glassbox/component/category_card.dart';
import 'package:glassbox/layout/layout.dart';
import 'package:glassbox/model/ads.dart';
import 'package:glassbox/model/home_category.dart';
import 'package:glassbox/providers/ads.dart';
import 'package:glassbox/providers/menu.dart';
import 'package:glassbox/providers/merchant.dart';
import 'package:glassbox/utils/shared_preference.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class Home extends StatefulWidget {
  Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with WidgetsBindingObserver {
  final _storage = const FlutterSecureStorage();
  late Future<List<HomeCategoryModel>> futureCategory;
  late Future<List<AdsModel>> futureAds;

  Future<List<HomeCategoryModel>> getCategoryList() async {
    var url = Uri.https('api.glassbox.id', '/v1/categories/home');
    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );
    final response = await http.get(url,
        headers: {'Authorization': 'Bearer ${token['access_token']}'});

    final List responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      for (var element in responseBody) {
        if (element['name'] == 'Recommended') {
          context.read<MenuProvider>().setRecommendedCategory(element['id']);
          break;
        }
      }
      return responseBody.map((e) => HomeCategoryModel.fromJSON(e)).toList();
    } else {
      throw Exception('Failed to load category list');
    }
  }

  Future<List<AdsModel>> getAdsList() async {
    var url = Uri.https('api.glassbox.id', '/v1/merchants/ads');
    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );
    final response = await http.get(url,
        headers: {'Authorization': 'Bearer ${token['access_token']}'});

    final List responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      List<AdsModel> adsList =
          responseBody.map((e) => AdsModel.fromJSON(e)).toList();
      context.read<AdsProvider>().adsList = adsList;
      return adsList;
    } else {
      throw Exception('Failed to load ads list');
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    futureCategory = getCategoryList();
    futureAds = getAdsList();
  }

  Widget _renderCategoryList(List<HomeCategoryModel> category) {
    return Row(
      children: category.asMap().entries.map((entry) {
        int idx = entry.key;
        HomeCategoryModel val = entry.value;
        return Expanded(
            child: CategoryCard(
          index: idx,
          text: val.name,
          imageUrl: val.image,
          textIcon: val.icon,
        ));
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: const EdgeInsets.all(16.0),
        child: MainLayout(child: LayoutBuilder(builder: (context, constraint) {
          return Column(mainAxisSize: MainAxisSize.min, children: [
            Row(
              children: [
                Expanded(
                  child: Center(
                    child: Column(
                      children: [
                        Text(
                          context.watch<MerchantProvider>().name,
                          style: TextStyle(
                              fontSize: 24.sp,
                              color: const Color(0xff383D43),
                              fontWeight: FontWeight.w500),
                        ),
                        Text(
                          context.watch<MerchantProvider>().tagLine,
                          style: TextStyle(
                              fontSize: 14.sp, color: const Color(0xff979AA0)),
                        )
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 50),
                Expanded(
                    child: Container(
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(15)),
                        child: Image.network(
                          // 'https://gbstorage.sgp1.digitaloceanspaces.com/assets/dev/a/f89c0d84ed1db2e3.png',
                          context.watch<MerchantProvider>().bannerImage,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 85.sp,
                          alignment: Alignment.center,
                        ))),
              ],
            ),
            const SizedBox(height: 8),
            Flexible(
                child: Container(
                    clipBehavior: Clip.hardEdge,
                    width: double.infinity,
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(15)),
                    child: FutureBuilder(
                        future: futureAds,
                        builder: ((context, snapshot) {
                          if (snapshot.hasData) {
                            final adsList = snapshot.data!;
                            return Carousel(
                              ads: adsList,
                            );
                          } else if (snapshot.hasError) {
                            return Text('${snapshot.error}');
                          }

                          return const Center(
                              child: CircularProgressIndicator());
                        })))),
            const SizedBox(height: 8),
            FutureBuilder(
                future: futureCategory,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    final categoryList = snapshot.data!;
                    return _renderCategoryList(categoryList);
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }

                  return const SizedBox(
                      height: 175,
                      child: Center(child: CircularProgressIndicator()));
                }),
          ]);
        })));
  }
}
