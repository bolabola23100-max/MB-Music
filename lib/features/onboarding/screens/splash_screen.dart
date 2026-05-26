import 'package:flutter/material.dart';
import 'package:music/core/constants/app_icons.dart';
import 'package:music/core/services/cache_helper.dart';
import 'package:music/features/home/screens/home_screen.dart';
import 'package:music/features/onboarding/screens/onboarding_screen.dart';

class SplashScreen extends StatefulWidget {
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _ringController;
  late AnimationController _waveController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;
  late Animation<double> ringOpacity;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1200),
    );
    _logoScale = CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    );
    _logoOpacity = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    _ringController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    ringOpacity = Tween<double>(begin: 0, end: 1).animate(_ringController);

    _waveController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _ringController.forward();
    Future.delayed(
      Duration(milliseconds: 700),
      () => _logoController.forward(),
    );

    // ✅ الـ navigation اتنقلت هنا بشكل صح
    Future.delayed(Duration(seconds: 4), () {
      if (!mounted) return;

      final nextScreen = CacheHelper.onboardingSeen
          ? const HomeScreen()
          : const OnboardingScreen();

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => nextScreen,
          transitionDuration: Duration(milliseconds: 800),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _ringController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Glow خلفي
            AnimatedBuilder(
              animation: _waveController,
              builder: (_, __) => Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Color(
                        0xFFFFB222,
                      ).withValues(alpha: 0.1 + _waveController.value * 0.1),
                      blurRadius: 80 + _waveController.value * 20,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),

            ScaleTransition(
              scale: _logoScale,
              child: FadeTransition(
                opacity: _logoOpacity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(AppIcons.logo, width: 160),
                    SizedBox(height: 12),
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (_, __) => Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(9, (i) => _buildWaveBar(i)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaveBar(int index) {
    final heights = [8.0, 16.0, 6.0, 22.0, 12.0, 20.0, 8.0, 14.0, 6.0];
    final animated = heights[index] * (0.4 + _waveController.value * 0.6);
    return AnimatedContainer(
      duration: Duration(milliseconds: 100),
      margin: EdgeInsets.symmetric(horizontal: 2),
      width: 3,
      height: animated,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(2),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF5D07A), Color(0xFFC8860A)],
        ),
      ),
    );
  }
}
