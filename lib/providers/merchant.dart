import 'package:flutter/foundation.dart';

class MerchantProvider with ChangeNotifier, DiagnosticableTreeMixin {
  String name = '';
  String tagLine = '';
  String logoImage = '';
  String bannerImage = '';

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    // TODO: implement debugFillProperties
    super.debugFillProperties(properties);
    properties.add(StringProperty('MerchantName', name));
    properties.add(StringProperty('TagLine', tagLine));
    properties.add(StringProperty('LogoImage', logoImage));
    properties.add(StringProperty('BannerImage', bannerImage));
  }
}
