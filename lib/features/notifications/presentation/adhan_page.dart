import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/brand_mark.dart';
import '../data/local_notification_service.dart';

class AdhanPage extends StatefulWidget {
  const AdhanPage({
    required this.prayerName,
    required this.notificationId,
    super.key,
  });

  final String prayerName;
  final int notificationId;

  @override
  State<AdhanPage> createState() => _AdhanPageState();
}

class _AdhanPageState extends State<AdhanPage> {
  bool _muted = false;

  Future<void> _stop() async {
    await LocalNotificationService.instance.stopAdhan(widget.notificationId);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greenDark,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const BrandMark(size: 112, dark: true),
                const SizedBox(height: 28),
                const Text(
                  'حان الآن موعد الأذان',
                  style: TextStyle(color: AppColors.white, fontSize: 22),
                ),
                const SizedBox(height: 10),
                Text(
                  'أذان ${widget.prayerName}',
                  style: const TextStyle(
                    color: AppColors.gold,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 52),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filled(
                      onPressed: () async {
                        setState(() => _muted = !_muted);
                        if (_muted) {
                          await LocalNotificationService.instance.stopAdhan(
                            widget.notificationId,
                          );
                        }
                      },
                      icon: Icon(_muted ? Icons.volume_off : Icons.volume_up),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.white.withValues(
                          alpha: 0.18,
                        ),
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.all(18),
                      ),
                    ),
                    const SizedBox(width: 24),
                    IconButton.filled(
                      onPressed: _stop,
                      icon: const Icon(Icons.stop_rounded),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: AppColors.ink,
                        padding: const EdgeInsets.all(18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  _muted
                      ? 'تم إيقاف صوت الأذان'
                      : 'يمكنك إيقاف الصوت في أي وقت',
                  style: TextStyle(
                    color: AppColors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
