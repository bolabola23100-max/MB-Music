import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:music/core/constants/app_colors.dart';

Widget svgOrImage(String src, {double? size, Color color = AppColors.white}) {
  if (src.endsWith(".svg")) {
    return SvgPicture.asset(
      src,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      width: size,
      height: size,
    );
  } else {
    return Image.asset(src, width: size, height: size, color: color);
  }
}
