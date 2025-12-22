import 'package:flutter/material.dart';

import '../../domain/alert_enums.dart';

TimeOfDay? _parseTimeOfDay(String? value) {
  if (value == null || value.isEmpty) {
    return null;
  }
  final parts = value.split(':');
  if (parts.length < 2) {
    return null;
  }
  final hour = int.tryParse(parts[0]) ?? 0;
  final minute = int.tryParse(parts[1]) ?? 0;
  return TimeOfDay(hour: hour, minute: minute);
}

String? _timeOfDayToString(TimeOfDay? time) {
  if (time == null) {
    return null;
  }
  final h = time.hour.toString().padLeft(2, '0');
  final m = time.minute.toString().padLeft(2, '0');
  return '$h:$m:00';
}

class NotificationPreference {
  NotificationPreference({
    this.id,
    required this.alertType,
    required this.inAppEnabled,
    required this.emailEnabled,
    required this.smsEnabled,
    required this.deliveryMode,
    required this.dailyDigestEnabled,
    this.digestTime,
    this.quietHoursFrom,
    this.quietHoursTo,
  });

  final String? id;
  final AlertType alertType;
  final bool inAppEnabled;
  final bool emailEnabled;
  final bool smsEnabled;
  final NotificationDeliveryMode deliveryMode;
  final bool dailyDigestEnabled;
  final TimeOfDay? digestTime;
  final TimeOfDay? quietHoursFrom;
  final TimeOfDay? quietHoursTo;

  NotificationPreference copyWith({
    bool? inAppEnabled,
    bool? emailEnabled,
    bool? smsEnabled,
    NotificationDeliveryMode? deliveryMode,
    bool? dailyDigestEnabled,
    TimeOfDay? digestTime,
    bool digestTimeCleared = false,
    TimeOfDay? quietHoursFrom,
    bool quietHoursFromCleared = false,
    TimeOfDay? quietHoursTo,
    bool quietHoursToCleared = false,
  }) {
    return NotificationPreference(
      id: id,
      alertType: alertType,
      inAppEnabled: inAppEnabled ?? this.inAppEnabled,
      emailEnabled: emailEnabled ?? this.emailEnabled,
      smsEnabled: smsEnabled ?? this.smsEnabled,
      deliveryMode: deliveryMode ?? this.deliveryMode,
      dailyDigestEnabled: dailyDigestEnabled ?? this.dailyDigestEnabled,
      digestTime: digestTimeCleared ? null : (digestTime ?? this.digestTime),
      quietHoursFrom: quietHoursFromCleared ? null : (quietHoursFrom ?? this.quietHoursFrom),
      quietHoursTo: quietHoursToCleared ? null : (quietHoursTo ?? this.quietHoursTo),
    );
  }

  factory NotificationPreference.fromJson(Map<String, dynamic> json) {
    return NotificationPreference(
      id: json['id'] as String?,
      alertType: AlertType.fromJson(json['alertType']),
      inAppEnabled: json['inAppEnabled'] as bool? ?? false,
      emailEnabled: json['emailEnabled'] as bool? ?? false,
      smsEnabled: json['smsEnabled'] as bool? ?? false,
      deliveryMode: NotificationDeliveryMode.fromJson(json['deliveryMode']),
      dailyDigestEnabled: json['dailyDigestEnabled'] as bool? ?? false,
      digestTime: _parseTimeOfDay(json['digestTime'] as String?),
      quietHoursFrom: _parseTimeOfDay(json['quietHoursFrom'] as String?),
      quietHoursTo: _parseTimeOfDay(json['quietHoursTo'] as String?),
    );
  }

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'alertType': alertType.apiValue,
        'inAppEnabled': inAppEnabled,
        'emailEnabled': emailEnabled,
        'smsEnabled': smsEnabled,
        'deliveryMode': deliveryMode.apiValue,
        'dailyDigestEnabled': dailyDigestEnabled,
        'digestTime': _timeOfDayToString(digestTime),
        'quietHoursFrom': _timeOfDayToString(quietHoursFrom),
        'quietHoursTo': _timeOfDayToString(quietHoursTo),
      };
}
