import 'package:flutter/material.dart';
import 'dart:async';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/startup_permissions_service.dart';
import '../../../core/widgets/brand_mark.dart';
import '../../home/presentation/home_page.dart';
import 'splash_controller.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  late final SplashController _controller;
  final _permissions = StartupPermissionsService();
  bool _openingHome = false;

  @override
  void initState() {
    super.initState();
    _controller = SplashController()..addListener(_onControllerChanged);
    _controller.start();
  }

  void _onControllerChanged() {
    if (_controller.isReady && mounted) {
      _openHome();
    }
  }

  Future<void> _openHome() async {
    if (_openingHome) return;
    _openingHome = true;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomePage()),
    );
    unawaited(_permissions.requestAll());
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onControllerChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greenDark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const BrandMark(size: 104, dark: true),
              const SizedBox(height: 24),
              Text(
                'قبلتي',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.white,
                  fontSize: 42,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'رفيقك إلى الطمأنينة',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.white.withValues(alpha: 0.72),
                ),
              ),
              const SizedBox(height: 48),
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.gold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
