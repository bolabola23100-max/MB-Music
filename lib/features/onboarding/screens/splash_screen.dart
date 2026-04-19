import 'package:flutter/material.dart';
import 'package:music/core/constants/app_icons.dart';
import 'package:music/core/routing/app_navigator.dart';
import 'package:music/features/home/screens/home_screen.dart';
import 'package:music/features/onboarding/screens/onboarding_screen.dart';
import 'package:music/core/services/cache_helper.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    if (CacheHelper.onboardingSeen) {
      AppNavigator.pushReplacement(context, const HomeScreen());
    } else {
      AppNavigator.pushReplacement(context, const OnboardingScreen());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(AppIcons.logo, height: 300, fit: BoxFit.cover),
          ],
        ),
      ),
    );
  }
}
