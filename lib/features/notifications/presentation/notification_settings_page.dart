import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/app_dialogs.dart';
import '../data/notification_settings_repository.dart';
import '../domain/notification_preferences.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  final _repository = NotificationSettingsRepository();
  NotificationPreferences _settings = const NotificationPreferences();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _repository.load();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _save(NotificationPreferences settings) async {
    setState(() => _settings = settings);
    await _repository.save(settings);
    if (!mounted) return;
    await AppDialogs.showInfo(
      context,
      title: 'تم الحفظ',
      message: settings.enabled
          ? 'تم حفظ إعدادات التنبيهات.'
          : 'تم إيقاف التنبيهات.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إعدادات التنبيهات')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppDimensions.pagePadding),
              children: [
                Text(
                  'ابقَ قريباً من صلاتك',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Text(
                  'اختر الطريقة التي تريحك لتذكيرك باقتراب الأذان ودخوله.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 24),
                Card(
                  child: SwitchListTile.adaptive(
                    value: _settings.enabled,
                    onChanged: (value) =>
                        _save(_settings.copyWith(enabled: value)),
                    activeThumbColor: AppColors.green,
                    title: const Text('تفعيل التنبيهات'),
                    subtitle: const Text('تنبيه قبل الصلاة وعند دخول وقتها'),
                    secondary: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.green,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'نوع التنبيه',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                _ModeCard(
                  icon: Icons.volume_up_outlined,
                  title: 'تنبيه صوتي عادي',
                  description: 'رسالة صوتية قصيرة مع صوت إشعار النظام',
                  selected: _settings.mode == NotificationMode.voiceNotice,
                  onTap: () => _save(
                    _settings.copyWith(mode: NotificationMode.voiceNotice),
                  ),
                ),
                const SizedBox(height: 10),
                _ModeCard(
                  icon: Icons.mosque_outlined,
                  title: 'أذان كامل',
                  description: 'يشغّل ملف الأذان المرخّص عند دخول وقت الصلاة',
                  selected: _settings.mode == NotificationMode.adhan,
                  onTap: () =>
                      _save(_settings.copyWith(mode: NotificationMode.adhan)),
                ),
                const SizedBox(height: 24),
                Text(
                  'التنبيه قبل الأذان بـ ${_settings.minutesBefore} دقائق.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.mint : AppColors.white,
      borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppDimensions.smallRadius),
            border: Border.all(
              color: selected ? AppColors.green : const Color(0xFFE8EDE9),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? AppColors.green : AppColors.muted),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.bodyLarge),
                    Text(
                      description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: selected
                    ? const Icon(
                        Icons.check_circle,
                        key: ValueKey('selected'),
                        color: AppColors.green,
                      )
                    : const Icon(
                        Icons.radio_button_unchecked,
                        key: ValueKey('unselected'),
                        color: AppColors.muted,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
