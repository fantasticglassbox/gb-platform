import 'package:flutter/material.dart';

class MenuProvider with ChangeNotifier {
  String _recommendedCategory = '';
  Map _activeMenu = {
    'menuId': '',
    'menuName': '',
    'menuImage': '',
    'menuPrice': 0,
    'menuDescription': ''
  };

  final List _menuCart = [];

  Map get activeMenu => _activeMenu;

  List get menuCart => _menuCart;

  String get recommendedCategory => _recommendedCategory;

  void setRecommendedCategory(String id) {
    _recommendedCategory = id;
    notifyListeners();
  }

  void addToCart(Map menuCart) {
    _menuCart.add(menuCart);
    notifyListeners();
  }

  void updateMenu(Map menuCart, int? index) {
    if (index != null) {
      _menuCart[index] = menuCart;
      notifyListeners();
    }
  }

  void setActiveMenu(Map activeMenu) {
    _activeMenu = activeMenu;
    notifyListeners();
  }
}
