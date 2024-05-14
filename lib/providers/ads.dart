import 'package:flutter/foundation.dart';
import 'package:glassbox/model/ads.dart';

class AdsProvider with ChangeNotifier, DiagnosticableTreeMixin {
  List<AdsModel> adsList = [];

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    // TODO: implement debugFillProperties
    super.debugFillProperties(properties);
    properties.add(IterableProperty('adsList', adsList));
  }
}
