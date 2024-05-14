import 'package:flutter/foundation.dart';

class CartProvider with ChangeNotifier {
  int _activeCartIndex = -1;
  Map _cartItems = {'items': null};

  Map get cartItems => _cartItems;
  int get activeCartIndex => _activeCartIndex;

  void setActiveCartIndex(int index) {
    _activeCartIndex = index;
    notifyListeners();
  }

  void setCart(Map cart) {
    _cartItems = cart;
    notifyListeners();
  }
}
