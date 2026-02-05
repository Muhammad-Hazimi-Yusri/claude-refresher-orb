/// Usage data model
/// Adapted from Usage4Claude by f-is-h
/// https://github.com/f-is-h/Usage4Claude

class UsageData {
  final LimitData? fiveHour;
  final LimitData? sevenDay;

  UsageData({this.fiveHour, this.sevenDay});

  factory UsageData.fromJson(Map<String, dynamic> json) {
    // The API returns data like:
    // {
    //   "five_hour": {"utilization": 85.0, "resets_at": "2026-02-05T00:00:00.267773+00:00"},
    //   "seven_day": null,
    //   ...
    // }
    
    LimitData? fiveHour;
    LimitData? sevenDay;

    // Parse five_hour
    final fiveHourData = json['five_hour'];
    if (fiveHourData != null && fiveHourData is Map<String, dynamic>) {
      fiveHour = LimitData.fromJson(fiveHourData);
    }

    // Parse seven_day (if present)
    final sevenDayData = json['seven_day'];
    if (sevenDayData != null && sevenDayData is Map<String, dynamic>) {
      sevenDay = LimitData.fromJson(sevenDayData);
    }

    return UsageData(fiveHour: fiveHour, sevenDay: sevenDay);
  }
}

class LimitData {
  final double percentage;
  final DateTime? resetsAt;

  LimitData({
    required this.percentage,
    this.resetsAt,
  });

  factory LimitData.fromJson(Map<String, dynamic> json) {
    // API uses "utilization" not "percentage"
    final utilization = json['utilization'];
    final resetsAtStr = json['resets_at'] as String?;
    
    return LimitData(
      percentage: (utilization is num) ? utilization.toDouble() : 0.0,
      resetsAt: resetsAtStr != null ? DateTime.tryParse(resetsAtStr) : null,
    );
  }

  Duration? get timeRemaining {
    if (resetsAt == null) return null;
    final remaining = resetsAt!.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  String get formattedTimeRemaining {
    if (resetsAt == null) return 'Unknown';

    final remaining = timeRemaining;
    if (remaining == null || remaining.isNegative || remaining == Duration.zero) {
      return 'Resetting soon';
    }

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;

    if (hours > 0) {
      return '${hours}h ${minutes}m left';
    } else {
      return '${minutes}m left';
    }
  }

  String get formattedResetTime {
    if (resetsAt == null) return '—';

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final resetDate = DateTime(resetsAt!.year, resetsAt!.month, resetsAt!.day);

    final timeStr = '${resetsAt!.hour.toString().padLeft(2, '0')}:${resetsAt!.minute.toString().padLeft(2, '0')}';

    if (resetDate == today) {
      return 'Today $timeStr';
    } else if (resetDate == tomorrow) {
      return 'Tomorrow $timeStr';
    } else {
      return '${resetsAt!.day}/${resetsAt!.month} $timeStr';
    }
  }
}
