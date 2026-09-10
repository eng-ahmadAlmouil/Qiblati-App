enum NotificationMode { voiceNotice, adhan }

class NotificationPreferences {
  const NotificationPreferences({
    this.enabled = true,
    this.mode = NotificationMode.voiceNotice,
    this.minutesBefore = 3,
  });

  final bool enabled;
  final NotificationMode mode;
  final int minutesBefore;

  NotificationPreferences copyWith({
    bool? enabled,
    NotificationMode? mode,
    int? minutesBefore,
  }) {
    return NotificationPreferences(
      enabled: enabled ?? this.enabled,
      mode: mode ?? this.mode,
      minutesBefore: minutesBefore ?? this.minutesBefore,
    );
  }
}
