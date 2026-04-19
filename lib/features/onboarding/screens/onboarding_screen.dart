import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:music/core/constants/app_colors.dart';
import 'package:music/core/constants/app_icons.dart';
import 'package:music/core/routing/app_navigator.dart';
import 'package:music/features/home/screens/home_screen.dart';
import 'package:music/core/services/cache_helper.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedLang = 'en';

  Future<void> _finish() async {
    CacheHelper.onboardingSeen = true;
    if (!mounted) return;
    AppNavigator.pushReplacement(context, const HomeScreen());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // ─── Logo ─────────────────────────────────────────────────────
              Image.asset(AppIcons.logo, height: 220, fit: BoxFit.contain),
              const SizedBox(height: 48),

              // ─── Language Buttons ─────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: _LangButton(
                      label: 'English',
                      flag: '🇺🇸',
                      isSelected: _selectedLang == 'en',
                      onTap: () {
                        setState(() => _selectedLang = 'en');
                        context.setLocale(const Locale('en'));
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _LangButton(
                      label: 'العربية',
                      flag: '🇪🇬',
                      isSelected: _selectedLang == 'ar',
                      onTap: () {
                        setState(() => _selectedLang = 'ar');
                        context.setLocale(const Locale('ar'));
                      },
                    ),
                  ),
                ],
              ),

              const Spacer(),

              // ─── Continue Button ──────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _finish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blue,
                    foregroundColor: AppColors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _selectedLang == 'ar' ? 'ابدأ' : 'Get Started',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Language Button Widget ───────────────────────────────────────────────────
class _LangButton extends StatelessWidget {
  final String label;
  final String flag;
  final bool isSelected;
  final VoidCallback onTap;

  const _LangButton({
    required this.label,
    required this.flag,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.blue.withValues(alpha: 0.15)
              : AppColors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.blue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: isSelected
                    ? AppColors.blue
                    : AppColors.white.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
