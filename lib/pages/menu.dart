import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:glassbox/component/all_category.dart';
import 'package:glassbox/component/guideline_drawer.dart';
import 'package:glassbox/component/menu_card.dart';
import 'package:glassbox/component/menu_category.dart';
import 'package:glassbox/component/menu_drawer.dart';
import 'package:glassbox/layout/layout.dart';
import 'package:glassbox/model/category.dart';
import 'package:glassbox/model/menu.dart';
import 'package:glassbox/providers/app.dart';
import 'package:glassbox/providers/menu.dart';
import 'package:glassbox/utils/icon.dart';
import 'package:glassbox/utils/shared_preference.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class MenuPage extends StatefulWidget {
  const MenuPage({super.key});

  @override
  State<MenuPage> createState() => _MenuPageState();
}

class _MenuPageState extends State<MenuPage> with TickerProviderStateMixin {
  bool showAsGrid = false;
  TabController? _tabController;
  int tabLength = 0;
  final _formKey = GlobalKey<FormBuilderState>();
  String savedValue = '';
  Map searchResult = {};
  int searchTotal = 0;
  int? cartIndex;
  bool searchMode = false;
  String activeCategory = 'All';
  String activeCategoryId = '';
  int activeCategoryIndex = 1;
  List scrollKey = [
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey(),
    GlobalKey()
  ];
  List<Map> listOfCategory = [];

  final _storage = const FlutterSecureStorage();
  late Future<List<CategoryModel>> futureMenu;
  late Future<Map> futureMenuWithCategory;

  // Scrollfeature
  final ItemScrollController itemScrollController = ItemScrollController();
  final ScrollOffsetController scrollOffsetController =
      ScrollOffsetController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final ScrollOffsetListener scrollOffsetListener =
      ScrollOffsetListener.create();

  void searchMenu(String query) async {
    setState(() {
      searchMode = true;
    });

    Map<String, dynamic> queryParam = {'keyword': query};

    var url =
        Uri.https('api.glassbox.id', '/v1/menus-with-category', queryParam);
    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );
    final response = await http.get(url,
        headers: {'Authorization': 'Bearer ${token['access_token']}'});

    if (response.statusCode == 200) {
      if (response.body == 'null') {
        setState(() {
          searchResult = {};
        });
      } else {
        final Map responseBody = json.decode(response.body);
        setState(() {
          searchResult = responseBody['data'];
          searchTotal = responseBody['total'];
        });
      }
    } else {
      throw Exception('Failed to load search menu');
    }
  }

  Future<List<CategoryModel>> getMenuList() async {
    var url = Uri.https('api.glassbox.id', '/v1/categories');
    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );
    final response = await http.get(url,
        headers: {'Authorization': 'Bearer ${token['access_token']}'});

    final List responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      List<CategoryModel> categoryList =
          responseBody.map((e) => CategoryModel.fromJSON(e)).toList();
      categoryList.removeWhere((element) => element.pos == -1);
      categoryList.sort((a, b) => a.pos.compareTo(b.pos));
      setState(() {
        listOfCategory = categoryList.map((e) {
          return {"id": e.id, "name": e.name, "icon": e.icon};
        }).toList();
      });
      return categoryList;
    } else {
      throw Exception('Failed to load ads list');
    }
  }

  Future<Map> getMenuCategoryList() async {
    var url = Uri.https('api.glassbox.id', '/v1/menus-with-category');
    final token = await _storage.readAll(
      aOptions: getAndroidOptions(),
    );
    final response = await http.get(url,
        headers: {'Authorization': 'Bearer ${token['access_token']}'});

    final Map responseBody = json.decode(response.body);

    if (response.statusCode == 200) {
      return responseBody['data'];
    } else {
      throw Exception('Failed to load ads list');
    }
  }

  @override
  void initState() {
    savedValue = _formKey.currentState?.value.toString() ?? '';
    // TODO: implement initState
    super.initState();
    _tabController = TabController(length: 0, vsync: this);
    futureMenu = getMenuList();
    futureMenuWithCategory = getMenuCategoryList();

    itemPositionsListener.itemPositions.addListener(() {
      if ((activeCategoryIndex - 1) !=
          itemPositionsListener.itemPositions.value.first.index) {
        setState(() {
          activeCategoryIndex =
              itemPositionsListener.itemPositions.value.first.index + 1;
        });
      }
    });
  }

  @override
  void dispose() {
    // TODO: implement dispose
    _tabController?.dispose();

    super.dispose();
  }

  Widget renderSearchResult(Map menu) {
    String query = _formKey.currentState?.value['query_input'];
    if (menu.isNotEmpty) {
      return LayoutBuilder(builder: (context, constraints) {
        final width = constraints.maxWidth;
        double aspectRatio = 1;
        int crossAxisCount = 4;
        if (width > 636 && width <= 1280) {
          if (showAsGrid) {
            aspectRatio = 0.65;
          } else {
            aspectRatio = 3.3;
          }
        } else if (width <= 636) {
          if (showAsGrid) {
            crossAxisCount = 3;
            aspectRatio = 0.67;
          } else {
            crossAxisCount = 2;
            aspectRatio = 2.0;
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.only(top: 10, bottom: 20),
              child: Text(
                '$searchTotal search results for "$query"',
                style: TextStyle(fontSize: 18.sp),
              ),
            ),
            Expanded(
                child: ScrollablePositionedList.builder(
                    itemScrollController: itemScrollController,
                    scrollOffsetController: scrollOffsetController,
                    itemPositionsListener: itemPositionsListener,
                    scrollOffsetListener: scrollOffsetListener,
                    itemCount: menu.length,
                    itemBuilder: (context, index) {
                      if (menu.length == index) {
                        return LayoutBuilder(builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          double emptySpaceHeight =
                              MediaQuery.of(context).size.height / 1.5;
                          if (width <= 636) {
                            emptySpaceHeight =
                                MediaQuery.of(context).size.height / 1.3;
                          }
                          return SizedBox(
                            height: emptySpaceHeight,
                          );
                        });
                      } else {
                        return LayoutBuilder(builder: (context, constraints) {
                          final width = constraints.maxWidth;
                          double aspectRatio = 1;
                          int crossAxisCount = 4;
                          if (width > 636 && width <= 1280) {
                            if (showAsGrid) {
                              aspectRatio = 0.9;
                            } else {
                              aspectRatio = 1.9;
                            }
                          } else if (width <= 636) {
                            if (showAsGrid) {
                              crossAxisCount = 3;
                              aspectRatio = 0.8;
                            } else {
                              crossAxisCount = 2;
                              aspectRatio = 2.8;
                            }
                          }
                          return MenuCategory(
                            categoryId: listOfCategory[
                                    int.parse(menu.keys.elementAt(index)) - 1]
                                ['id'],
                            categoryName: listOfCategory[
                                    int.parse(menu.keys.elementAt(index)) - 1]
                                ['name'],
                            categoryIcon: listOfCategory[
                                    int.parse(menu.keys.elementAt(index)) - 1]
                                ['icon'],
                            menus: menu.values.elementAt(index),
                            showAsGrid: showAsGrid,
                            crossAxisCount: crossAxisCount,
                            cardAspectRatio: aspectRatio,
                            imageSize: 150,
                          );
                        });
                      }
                    })),
          ],
        );
      });
    } else {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const FaIcon(
              FontAwesomeIcons.magnifyingGlass,
              size: 60,
              color: Color(0xffC1C3C7),
            ),
            const SizedBox(
              height: 20,
            ),
            Text('0 search results for "$query"',
                style: TextStyle(fontSize: 14.sp)),
            const SizedBox(
              height: 20,
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(
                    foregroundColor:
                        Colors.white, //change background color of button
                    backgroundColor: Theme.of(context).primaryColor),
                onPressed: () {
                  setState(() {
                    searchMode = false;
                    _formKey.currentState!.fields['query_input']?.didChange('');
                  });
                },
                child:
                    Text('Change Keyword', style: TextStyle(fontSize: 14.sp)))
          ],
        ),
      );
    }
  }

  bool checkMenuIsInCart(String menuId) {
    List cartItem = context.watch<MenuProvider>().menuCart;
    bool isInCart = false;
    for (var (index, item) in cartItem.indexed) {
      if (menuId == item['menu_id']) {
        setState(() {
          cartIndex = index;
        });
        isInCart = true;
        break;
      }
    }
    return isInCart;
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
        drawer: context.watch<AppProvider>().isMenuDrawer
            ? MenuDrawer(
                menuId: context.watch<MenuProvider>().activeMenu['menuId'],
              )
            : const GuidelineDrawer(),
        child: Column(children: [
          Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                      width: 300,
                      child: FormBuilder(
                        key: _formKey,
                        child: FormBuilderTextField(
                          validator: FormBuilderValidators.compose([
                            FormBuilderValidators.required(),
                            FormBuilderValidators.minLength(3)
                          ]),
                          name: 'query_input',
                          onSubmitted: (value) {
                            if (_formKey.currentState!.saveAndValidate()) {
                              searchMenu(value!);
                            }
                          },
                          decoration: InputDecoration(
                            labelText: 'Search $activeCategory menu',
                            suffixIcon: Icon(
                              Icons.search,
                              color: Theme.of(context).primaryColor,
                            ),
                            hintText: 'Search menu',
                            enabledBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                  color: Color.fromRGBO(205, 205, 205, 1.0)),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderSide: const BorderSide(
                                color: Colors.black,
                                width: 1,
                              ),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            isDense: true,
                          ),
                        ),
                      )),
                  const SizedBox(width: 15),
                  searchMode
                      ? InkWell(
                          onTap: () {
                            setState(() {
                              searchMode = false;
                              _formKey.currentState!.fields['query_input']
                                  ?.didChange('');
                            });
                          },
                          child: Text(
                            'View All Menu',
                            style: TextStyle(
                                fontSize: 20.sp,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor),
                          ))
                      : const SizedBox(),
                  Expanded(
                      child: Container(
                          child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      const Icon(Icons.grid_4x4_outlined),
                      Switch(
                          value: showAsGrid,
                          activeColor: Theme.of(context).primaryColor,
                          onChanged: (value) {
                            setState(() {
                              showAsGrid = value;
                            });
                          }),
                      const SizedBox(width: 10),
                      Builder(builder: (context) {
                        return IconButton(
                            onPressed: () {
                              context
                                  .read<AppProvider>()
                                  .setIsMenuDrawer(false);
                              Scaffold.of(context).openEndDrawer();
                            },
                            icon: Icon(
                              Icons.info_rounded,
                              color: Theme.of(context).primaryColor,
                            ));
                      }),
                    ],
                  )))
                ],
              )),
          FutureBuilder(
              future: futureMenu,
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  final menuList = snapshot.data;
                  return SizedBox(
                    height: 50.sp,
                    child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: menuList!.map((item) {
                          return InkWell(
                              onTap: () {
                                setState(() {
                                  activeCategoryIndex = item.pos;
                                });

                                itemScrollController.scrollTo(
                                    index: activeCategoryIndex - 1,
                                    duration: Duration(milliseconds: 300),
                                    curve: Curves.easeInOutCubic);
                              },
                              child: Container(
                                  decoration: activeCategoryIndex == item.pos
                                      ? BoxDecoration(
                                          border: Border(
                                              bottom: BorderSide(
                                                  width: 3.0,
                                                  color: Color(0xff0c75ff))))
                                      : null,
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 20.sp),
                                  child: Row(children: [
                                    GBIcon.getIcon(item.icon),
                                    const SizedBox(width: 8),
                                    Text(
                                      item.name,
                                      style: TextStyle(fontSize: 16.sp),
                                    )
                                  ])));
                        }).toList()),
                  );
                } else if (snapshot.hasError) {
                  return Text('${snapshot.error}');
                }

                return const Center(child: CircularProgressIndicator());
              }),
          Expanded(
              child: Container(
                  color: const Color.fromRGBO(247, 247, 247, 1.0),
                  padding:
                      const EdgeInsets.only(left: 16.0, right: 16.0, top: 16.0),
                  child: Container(
                      color: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: searchMode
                          ? renderSearchResult(searchResult)
                          : FutureBuilder(
                              future: futureMenuWithCategory,
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  final menuList = snapshot.data;
                                  return ScrollablePositionedList.builder(
                                      itemScrollController:
                                          itemScrollController,
                                      scrollOffsetController:
                                          scrollOffsetController,
                                      itemPositionsListener:
                                          itemPositionsListener,
                                      scrollOffsetListener:
                                          scrollOffsetListener,
                                      itemCount: listOfCategory.length + 1,
                                      itemBuilder: (context, index) {
                                        if (listOfCategory.length == index) {
                                          return LayoutBuilder(
                                              builder: (context, constraints) {
                                            final width = constraints.maxWidth;
                                            double emptySpaceHeight =
                                                MediaQuery.of(context)
                                                        .size
                                                        .height /
                                                    1.5;
                                            if (width <= 636) {
                                              emptySpaceHeight =
                                                  MediaQuery.of(context)
                                                          .size
                                                          .height /
                                                      1.3;
                                            }
                                            return SizedBox(
                                              height: emptySpaceHeight,
                                            );
                                          });
                                        } else {
                                          return LayoutBuilder(
                                              builder: (context, constraints) {
                                            final width = constraints.maxWidth;
                                            double aspectRatio = 1;
                                            int crossAxisCount = 4;
                                            if (width > 636 && width <= 1280) {
                                              if (showAsGrid) {
                                                aspectRatio = 0.9;
                                              } else {
                                                aspectRatio = 1.9;
                                              }
                                            } else if (width <= 636) {
                                              if (showAsGrid) {
                                                crossAxisCount = 3;
                                                aspectRatio = 0.8;
                                              } else {
                                                crossAxisCount = 2;
                                                aspectRatio = 2.8;
                                              }
                                            }
                                            return MenuCategory(
                                              categoryId: listOfCategory[index]
                                                  ['id'],
                                              categoryName:
                                                  listOfCategory[index]['name'],
                                              categoryIcon:
                                                  listOfCategory[index]['icon'],
                                              menus: menuList?[
                                                  (index + 1).toString()],
                                              showAsGrid: showAsGrid,
                                              crossAxisCount: crossAxisCount,
                                              cardAspectRatio: aspectRatio,
                                              imageSize: 150,
                                            );
                                          });
                                        }
                                      });
                                } else if (snapshot.hasError) {
                                  return Text('${snapshot.error}');
                                }

                                return const Center(
                                    child: CircularProgressIndicator());
                              }))))
        ]));
  }
}
