import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class GBIcon {
  static FaIcon getIcon(String iconString, {Color? color, double size = 16}) {
    if (iconString == 'special-offers') {
      return FaIcon(FontAwesomeIcons.tag,
          size: size, color: color ?? const Color(0xffFFC772));
    } else if (iconString == 'recommended') {
      return FaIcon(FontAwesomeIcons.thumbsUp,
          size: size, color: color ?? const Color(0xff52DD67));
    } else if (iconString == 'trending') {
      return FaIcon(FontAwesomeIcons.arrowTrendUp,
          size: size, color: color ?? const Color(0xff4D9CFF));
    } else if (iconString == 'new') {
      return FaIcon(FontAwesomeIcons.star,
          size: size, color: color ?? const Color(0xffFE827B));
    } else if (iconString == 'drinks') {
      return FaIcon(FontAwesomeIcons.glassWater,
          size: size, color: color ?? const Color(0xffFE827B));
    } else if (iconString == 'sugar') {
      return FaIcon(FontAwesomeIcons.cookie,
          size: size, color: color ?? const Color(0xffFE827B));
    } else if (iconString == 'chili') {
      return FaIcon(FontAwesomeIcons.pepperHot,
          size: size, color: color ?? const Color(0xffFE827B));
    } else if (iconString == 'shrimp') {
      return FaIcon(FontAwesomeIcons.shrimp,
          size: size, color: color ?? const Color(0xffFE827B));
    }
    return FaIcon(FontAwesomeIcons.tag,
        size: size, color: color ?? const Color(0xffFE827B));
  }
}
