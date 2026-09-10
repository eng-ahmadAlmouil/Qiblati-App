import 'package:flutter/material.dart';
import 'dart:async';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/utils/app_date.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/liquid_glass.dart';
import 'qibla_controller.dart';

class QiblaPage extends StatefulWidget {
  const QiblaPage({super.key});

  @override
  State<QiblaPage> createState() => _QiblaPageState();
}

class _QiblaPageState extends State<QiblaPage> with WidgetsBindingObserver {
  late final QiblaController _controller;
  QiblaStatus? _shownStatus;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = QiblaController()..addListener(_refresh);
    unawaited(_controller.enableLocation());
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
    final status = _controller.status;
    if (status != QiblaStatus.idle &&
        status != QiblaStatus.loading &&
        status != QiblaStatus.ready &&
        status != _shownStatus) {
      _shownStatus = status;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          AppDialogs.showError(
            context,
            title: 'تعذر تحديد اتجاه القبلة',
            message: _statusMessage,
            onRetry: _controller.retryLocation,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      unawaited(_controller.pauseCompass());
    } else if (state == AppLifecycleState.resumed) {
      if (_controller.status == QiblaStatus.locationDisabled ||
          _controller.status == QiblaStatus.permissionDenied) {
        unawaited(_controller.retryLocation());
      } else {
        _controller.resumeCompass();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppDimensions.pagePadding,
          AppDimensions.pagePadding,
          AppDimensions.pagePadding,
          16,
        ),
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny_outlined, color: AppColors.gold),
              const SizedBox(width: 10),
              Text(
                'السلام عليكم',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const Spacer(),
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.notifications_none_rounded),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'وجهتك إلى القبلة',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          const SizedBox(height: 8),
          Text(
            'اعثر على اتجاه الكعبة بدقة أينما كنت.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppDimensions.sectionGap),
          _CompassDial(
            relativeBearing: _controller.relativeBearing,
            headingLabel: _headingLabel,
          ),
          const SizedBox(height: 14),
          _DateCard(date: DateTime.now()),
          const SizedBox(height: 20),
          if (_controller.status == QiblaStatus.idle ||
              _controller.status == QiblaStatus.locationDisabled ||
              _controller.status == QiblaStatus.permissionDenied ||
              _controller.status == QiblaStatus.error)
            Card(
              margin: EdgeInsets.zero,
              color: AppColors.white,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.green,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _statusMessage,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    if (_controller.status == QiblaStatus.loading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      IconButton(
                        onPressed: _controller.retryLocation,
                        tooltip: 'تجديد الموقع',
                        icon: const Icon(Icons.refresh_rounded),
                        color: AppColors.green,
                      ),
                  ],
                ),
              ),
            )
          else if (_controller.status == QiblaStatus.sensorUnavailable)
            const _SensorUnavailableCard()
          else if (_controller.status == QiblaStatus.loading)
            const _LoadingCard()
          else
            const _LocationReadyCard(),
        ],
      ),
    );
  }

  String get _headingLabel {
    final bearing = _controller.relativeBearing;
    if (bearing == null) return 'حرّك هاتفك';
    return '${bearing.toStringAsFixed(0)}°';
  }

  String get _statusMessage {
    switch (_controller.status) {
      case QiblaStatus.locationDisabled:
        return 'خدمة الموقع متوقفة. فعّلها للحصول على اتجاه القبلة.';
      case QiblaStatus.permissionDenied:
        return 'نحتاج إذن الموقع حتى نحدد اتجاه القبلة بدقة.';
      case QiblaStatus.error:
        return 'تعذر تحديد موقعك حالياً. حاول مرة أخرى.';
      case QiblaStatus.sensorUnavailable:
        return 'البوصلة غير متاحة على هذا الجهاز.';
      case QiblaStatus.idle:
      default:
        return 'فعّل الموقع للحصول على اتجاه دقيق لمكانك.';
    }
  }
}

class _CompassDial extends StatelessWidget {
  const _CompassDial({
    required this.relativeBearing,
    required this.headingLabel,
  });

  final double? relativeBearing;
  final String headingLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 350,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.greenDark, AppColors.ink],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(AppDimensions.largeRadius),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F4D42),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 270,
            height: 270,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.gold.withValues(alpha: 0.36),
                width: 2,
              ),
              gradient: RadialGradient(
                colors: [
                  AppColors.green.withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          Container(
            width: 208,
            height: 208,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.white.withValues(alpha: 0.2)),
            ),
          ),
          const Positioned(top: 28, child: _CompassPoint('N')),
          const Positioned(bottom: 28, child: _CompassPoint('S')),
          const Positioned(left: 32, child: _CompassPoint('W')),
          const Positioned(right: 32, child: _CompassPoint('E')),
          Transform.rotate(
            angle: ((relativeBearing ?? 0) * 3.1415926535) / 180,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 3),
                    boxShadow: const [
                      BoxShadow(color: Color(0x55000000), blurRadius: 14),
                    ],
                  ),
                  child: const Icon(
                    Icons.mosque_rounded,
                    color: AppColors.greenDark,
                    size: 42,
                  ),
                ),
                Container(
                  width: 4,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 4,
            child: Text(
              headingLabel,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CompassPoint extends StatelessWidget {
  const _CompassPoint(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: AppColors.white,
      fontSize: 13,
      fontWeight: FontWeight.w700,
    ),
  );
}

class _DateCard extends StatelessWidget {
  const _DateCard({required this.date});

  final DateTime date;

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      borderRadius: AppDimensions.cardRadius,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
        child: Row(
          children: [
            const Icon(Icons.calendar_month_rounded, color: AppColors.green),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppDate.hijri(date),
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  Text(
                    AppDate.gregorian(date),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationReadyCard extends StatelessWidget {
  const _LocationReadyCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.mint,
      elevation: 0,
      child: ListTile(
        leading: const Icon(Icons.check_circle_outline, color: AppColors.green),
        title: const Text('تم تحديد موقعك'),
        subtitle: const Text('وجّه هاتفك نحو السهم للوصول إلى القبلة'),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: ListTile(
        leading: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        title: Text('جارٍ تحديد اتجاه القبلة...'),
      ),
    );
  }
}

class _SensorUnavailableCard extends StatelessWidget {
  const _SensorUnavailableCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      margin: EdgeInsets.zero,
      color: Color(0xFFFFF4DF),
      elevation: 0,
      child: ListTile(
        leading: Icon(Icons.explore_off_outlined, color: AppColors.gold),
        title: Text('البوصلة غير متاحة'),
        subtitle: Text(
          'يمكنك استخدام جهاز يدعم حساس الاتجاه للوصول إلى القبلة.',
        ),
      ),
    );
  }
}
