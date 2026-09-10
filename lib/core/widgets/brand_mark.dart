import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 76, this.dark = false});

  final double size;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: dark ? AppColors.white.withValues(alpha: 0.14) : AppColors.mint,
        shape: BoxShape.circle,
        border: Border.all(
          color: dark
              ? AppColors.gold
              : AppColors.green.withValues(alpha: 0.15),
        ),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/images/logo_qiblati.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
        ),
      ),
    );
  }
}
