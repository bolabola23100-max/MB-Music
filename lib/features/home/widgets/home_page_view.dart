import 'package:flutter/material.dart';

class HomePageView extends StatelessWidget {
  final PageController controller;
  final List<Widget> pages;
  final ValueChanged<int> onPageChanged;

  const HomePageView({
    super.key,
    required this.controller,
    required this.pages,
    required this.onPageChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PageView(
      controller: controller,
      physics: const BouncingScrollPhysics(),
      onPageChanged: onPageChanged,
      children: pages,
    );
  }
}
