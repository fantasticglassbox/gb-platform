import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glassbox/model/setting.dart';

class AppProvider with ChangeNotifier, DiagnosticableTreeMixin {
  int _activeNavigationRailIndex = 0;
  int _tabPosition = 0;
  bool _isMenuDrawer = false;
  final GlobalKey<ScaffoldState> _key = GlobalKey();
  // TEMP STORE RECOMMENDED ID CAT
  String _recommendedId = '';
  String _sessionStatus = '';
  String _lastRoute = '';
  SettingModel _setting =
      SettingModel(enableOrdering: true, defaultImage: true);

  int get activeNavigationRailIndex => _activeNavigationRailIndex;
  String get recommendedId => _recommendedId;
  String get sessionStatus => _sessionStatus;
  String get lastRoute => _lastRoute;
  int get tabPosition => _tabPosition;
  GlobalKey<ScaffoldState> get key => _key;
  SettingModel get setting => _setting;

  bool get isMenuDrawer => _isMenuDrawer;

  void setSetting(SettingModel setting) {
    _setting = setting;
    notifyListeners();
  }

  void setActiveNavigationRailIndex(int index) {
    _activeNavigationRailIndex = index;
    notifyListeners();
  }

  void setTabPosition(int index) {
    _tabPosition = index;
    notifyListeners();
  }

  void setIsMenuDrawer(bool value) {
    _isMenuDrawer = value;
    notifyListeners();
  }

  void setRecommendedId(String id) {
    _recommendedId = id;
    notifyListeners();
  }

  void setLastRoute(String? route) {
    _lastRoute = route ?? '/main';
    notifyListeners();
  }

  void setSessionStatus(String status) {
    _sessionStatus = status;
    notifyListeners();
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    // TODO: implement debugFillProperties
    super.debugFillProperties(properties);
    properties.add(
        IntProperty('activeNavigationRailIndex', _activeNavigationRailIndex));
    properties.add(IntProperty('tabPosition', _tabPosition));
    properties.add(FlagProperty('isMenuDrawer', value: _isMenuDrawer));
  }
}
