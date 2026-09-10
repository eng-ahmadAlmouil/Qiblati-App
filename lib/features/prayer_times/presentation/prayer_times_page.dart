import 'package:flutter/material.dart';
import 'dart:async';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../../../core/widgets/liquid_glass.dart';
import '../../notifications/presentation/notification_settings_page.dart';
import '../domain/prayer_time.dart';
import 'prayer_times_controller.dart';

class PrayerTimesPage extends StatefulWidget {
  const PrayerTimesPage({super.key});

  @override
  State<PrayerTimesPage> createState() => _PrayerTimesPageState();
}

class _PrayerTimesPageState extends State<PrayerTimesPage> {
  late final PrayerTimesController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PrayerTimesController()..addListener(_refresh);
    _controller.load();
  }

  void _refresh() {
    if (!mounted) return;
    setState(() {});
    final message = _controller.notificationMessage;
    if (message != null) {
      _controller.clearNotificationMessage();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        AppDialogs.showError(
          context,
          title: 'تنبيه الإشعارات',
          message: message,
          onRetry: _openNotificationSettings,
        );
      });
    }
    if (_controller.status == PrayerTimesStatus.error) {
      final error = _controller.errorMessage;
      if (error != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            AppDialogs.showError(
              context,
              title: 'تعذر تحميل المواقيت',
              message: error,
              onRetry: _controller.load,
            );
          }
        });
      }
    }
  }

  void _openNotificationSettings() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationSettingsPage()),
    );
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.green,
        onRefresh: _controller.load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppDimensions.pagePadding,
            AppDimensions.pagePadding,
            AppDimensions.pagePadding,
            16,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'مواقيت الصلاة',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: () => _controller.load(forceRefresh: true),
                  tooltip: 'تحديث المواقيت',
                  icon: const Icon(Icons.refresh),
                ),
                IconButton.filledTonal(
                  onPressed: _openNotificationSettings,
                  tooltip: 'إعدادات التنبيهات',
                  icon: const Icon(Icons.notifications_outlined),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'صلاتك في وقتها، وطمأنينتك أقرب.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppDimensions.sectionGap),
            _buildContent(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_controller.status) {
      case PrayerTimesStatus.idle:
      case PrayerTimesStatus.loading:
        return const _LoadingState();
      case PrayerTimesStatus.error:
        return _ErrorState(
          message: _controller.errorMessage ?? 'تعذر تحميل المواقيت.',
          onRetry: _controller.load,
        );
      case PrayerTimesStatus.ready:
        final result = _controller.result;
        if (result == null) return const _LoadingState();
        return _PrayerSchedule(result: result);
    }
  }
}

class _PrayerSchedule extends StatelessWidget {
  const _PrayerSchedule({required this.result});

  final PrayerTimesResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NextPrayerCard(result: result),
        const SizedBox(height: 14),
        LiquidGlass(
          color: AppColors.greenDark.withValues(alpha: 0.82),
          borderRadius: AppDimensions.cardRadius,
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const Icon(Icons.location_on_outlined, color: AppColors.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  result.timezone ?? 'موقعك الحالي',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AppColors.white,
                    fontSize: 17,
                  ),
                ),
              ),
              Text(
                _formatDate(result.date),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Column(
            children: [
              for (var index = 0; index < result.prayers.length; index++) ...[
                _PrayerRow(prayer: result.prayers[index]),
                if (index < result.prayers.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}';
}

class _NextPrayerCard extends StatelessWidget {
  const _NextPrayerCard({required this.result});

  final PrayerTimesResult result;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final upcoming =
        result.prayers
            .map((prayer) => (prayer: prayer, date: _date(prayer.time, now)))
            .where((item) => item.date.isAfter(now))
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));
    final next = upcoming.first;
    final remaining = next.date.difference(now);
    return _LiveNextPrayerCard(
      prayerName: next.prayer.arabicName,
      prayerTime: next.prayer.time,
      remaining: remaining,
    );
  }

  DateTime _date(String value, DateTime now) {
    final parts = value.split(':');
    final hour = int.tryParse(parts.first) ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    var date = DateTime(now.year, now.month, now.day, hour, minute);
    if (!date.isAfter(now)) date = date.add(const Duration(days: 1));
    return date;
  }
}

class _LiveNextPrayerCard extends StatefulWidget {
  const _LiveNextPrayerCard({
    required this.prayerName,
    required this.prayerTime,
    required this.remaining,
  });

  final String prayerName;
  final String prayerTime;
  final Duration remaining;

  @override
  State<_LiveNextPrayerCard> createState() => _LiveNextPrayerCardState();
}

class _LiveNextPrayerCardState extends State<_LiveNextPrayerCard> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.remaining;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_remaining > Duration.zero) {
          _remaining -= const Duration(seconds: 1);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);
    return LiquidGlass(
      color: AppColors.mint.withValues(alpha: 0.88),
      borderRadius: AppDimensions.cardRadius,
      child: ListTile(
        leading: const Icon(
          Icons.notifications_active_outlined,
          color: AppColors.green,
        ),
        title: Text(
          'الصلاة القادمة: ${widget.prayerName}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          'متبقي ${hours > 0 ? '$hours ساعة و' : ''}'
          '$minutes دقيقة و${seconds.toString().padLeft(2, '0')} ثانية',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        trailing: Text(
          widget.prayerTime,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.greenDark,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  const _PrayerRow({required this.prayer});

  final PrayerTime prayer;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
      leading: Text(prayer.icon, style: const TextStyle(fontSize: 22)),
      title: Text(
        prayer.arabicName,
        style: Theme.of(
          context,
        ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      trailing: Text(
        prayer.time,
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(color: AppColors.green, fontSize: 18),
      ),
      subtitle: Text(_sunnah(prayer.name)),
    );
  }

  String _sunnah(String name) {
    const sunnah = {
      'Fajr': 'السنة القبلية: ركعتان',
      'Dhuhr': 'القبلية: 4 ركعات • البعدية: ركعتان',
      'Asr': 'السنة القبلية: 4 ركعات',
      'Maghrib': 'السنة البعدية: ركعتان',
      'Isha': 'السنة البعدية: ركعتان',
    };
    return sunnah[name] ?? '';
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(36),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              color: AppColors.gold,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
