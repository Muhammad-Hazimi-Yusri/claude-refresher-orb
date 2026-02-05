import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  late SharedPreferences _prefs;

  // Keys
  static const _keySessionKey = 'session_key';
  static const _keyOrganizationId = 'organization_id';
  static const _keyHasCompletedSetup = 'has_completed_setup';
  static const _keyWorkingHoursEnabled = 'working_hours_enabled';
  static const _keyWorkingHoursStart = 'working_hours_start';
  static const _keyWorkingHoursEnd = 'working_hours_end';
  static const _keyDailyKickstartEnabled = 'daily_kickstart_enabled';
  static const _keyDailyKickstartHour = 'daily_kickstart_hour';
  static const _keyDailyKickstartMinute = 'daily_kickstart_minute';
  static const _keyNotificationsPaused = 'notifications_paused';
  static const _keyLastUsagePercentage = 'last_usage_percentage';
  static const _keyLastResetTime = 'last_reset_time';
  
  // Smart timer settings
  static const _keyWindowStartTime = 'window_start_time';
  static const _keyPreResetMinutes = 'pre_reset_minutes';
  static const _keyPostResetMinutes = 'post_reset_minutes';
  static const _keyDeadlineEnabled = 'deadline_enabled';
  static const _keyDeadlineHour = 'deadline_hour';
  static const _keyDeadlineMinutesBefore = 'deadline_minutes_before';

  // Cached values
  String? _sessionKey;
  String? _organizationId;
  bool _hasCompletedSetup = false;
  bool _workingHoursEnabled = true;
  int _workingHoursStart = 6;
  int _workingHoursEnd = 24;
  bool _dailyKickstartEnabled = false;
  int _dailyKickstartHour = 6;
  int _dailyKickstartMinute = 0;
  bool _notificationsPaused = false;
  double _lastUsagePercentage = 0;
  DateTime? _lastResetTime;
  
  // Smart timer values
  DateTime? _windowStartTime;
  int _preResetMinutes = 5;
  int _postResetMinutes = 5;
  bool _deadlineEnabled = true;
  int _deadlineHour = 12;  // Noon by default
  int _deadlineMinutesBefore = 10;

  // Getters
  String? get sessionKey => _sessionKey;
  String? get organizationId => _organizationId;
  bool get hasCompletedSetup => _hasCompletedSetup;
  bool get hasCredentials => _sessionKey != null && _organizationId != null;
  bool get workingHoursEnabled => _workingHoursEnabled;
  int get workingHoursStart => _workingHoursStart;
  int get workingHoursEnd => _workingHoursEnd;
  bool get dailyKickstartEnabled => _dailyKickstartEnabled;
  int get dailyKickstartHour => _dailyKickstartHour;
  int get dailyKickstartMinute => _dailyKickstartMinute;
  bool get notificationsPaused => _notificationsPaused;
  double get lastUsagePercentage => _lastUsagePercentage;
  DateTime? get lastResetTime => _lastResetTime;
  
  // Smart timer getters
  DateTime? get windowStartTime => _windowStartTime;
  int get preResetMinutes => _preResetMinutes;
  int get postResetMinutes => _postResetMinutes;
  bool get deadlineEnabled => _deadlineEnabled;
  int get deadlineHour => _deadlineHour;
  int get deadlineMinutesBefore => _deadlineMinutesBefore;
  
  // Computed: when does the window reset?
  DateTime? get windowResetTime => _windowStartTime?.add(const Duration(hours: 5));
  
  // Is window currently active?
  bool get isWindowActive {
    if (_windowStartTime == null) return false;
    final resetTime = windowResetTime!;
    return DateTime.now().isBefore(resetTime);
  }
  
  // Time remaining until reset
  Duration? get timeUntilReset {
    if (!isWindowActive) return null;
    return windowResetTime!.difference(DateTime.now());
  }

  String get workingHoursDescription {
    final startStr = '${_workingHoursStart.toString().padLeft(2, '0')}:00';
    final endStr = _workingHoursEnd == 24 ? '00:00' : '${_workingHoursEnd.toString().padLeft(2, '0')}:00';
    return '$startStr - $endStr';
  }

  String get dailyKickstartDescription {
    return '${_dailyKickstartHour.toString().padLeft(2, '0')}:${_dailyKickstartMinute.toString().padLeft(2, '0')}';
  }
  
  String get deadlineDescription {
    return '${_deadlineHour.toString().padLeft(2, '0')}:00';
  }

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSettings();
  }

  Future<void> _loadSettings() async {
    // Load all settings from SharedPreferences
    _sessionKey = _prefs.getString(_keySessionKey);
    _organizationId = _prefs.getString(_keyOrganizationId);
    _hasCompletedSetup = _prefs.getBool(_keyHasCompletedSetup) ?? false;
    _workingHoursEnabled = _prefs.getBool(_keyWorkingHoursEnabled) ?? true;
    _workingHoursStart = _prefs.getInt(_keyWorkingHoursStart) ?? 6;
    _workingHoursEnd = _prefs.getInt(_keyWorkingHoursEnd) ?? 24;
    _dailyKickstartEnabled = _prefs.getBool(_keyDailyKickstartEnabled) ?? false;
    _dailyKickstartHour = _prefs.getInt(_keyDailyKickstartHour) ?? 6;
    _dailyKickstartMinute = _prefs.getInt(_keyDailyKickstartMinute) ?? 0;
    _notificationsPaused = _prefs.getBool(_keyNotificationsPaused) ?? false;
    _lastUsagePercentage = _prefs.getDouble(_keyLastUsagePercentage) ?? 0;
    
    final resetTimeStr = _prefs.getString(_keyLastResetTime);
    _lastResetTime = resetTimeStr != null ? DateTime.tryParse(resetTimeStr) : null;
    
    // Smart timer settings
    final windowStartStr = _prefs.getString(_keyWindowStartTime);
    _windowStartTime = windowStartStr != null ? DateTime.tryParse(windowStartStr) : null;
    _preResetMinutes = _prefs.getInt(_keyPreResetMinutes) ?? 5;
    _postResetMinutes = _prefs.getInt(_keyPostResetMinutes) ?? 5;
    _deadlineEnabled = _prefs.getBool(_keyDeadlineEnabled) ?? true;
    _deadlineHour = _prefs.getInt(_keyDeadlineHour) ?? 12;
    _deadlineMinutesBefore = _prefs.getInt(_keyDeadlineMinutesBefore) ?? 10;

    notifyListeners();
  }

  Future<void> setSessionKey(String? value) async {
    _sessionKey = value;
    if (value != null) {
      await _prefs.setString(_keySessionKey, value);
    } else {
      await _prefs.remove(_keySessionKey);
    }
    notifyListeners();
  }

  Future<void> setOrganizationId(String? value) async {
    _organizationId = value;
    if (value != null) {
      await _prefs.setString(_keyOrganizationId, value);
    } else {
      await _prefs.remove(_keyOrganizationId);
    }
    notifyListeners();
  }

  Future<void> setHasCompletedSetup(bool value) async {
    _hasCompletedSetup = value;
    await _prefs.setBool(_keyHasCompletedSetup, value);
    notifyListeners();
  }

  Future<void> setWorkingHoursEnabled(bool value) async {
    _workingHoursEnabled = value;
    await _prefs.setBool(_keyWorkingHoursEnabled, value);
    notifyListeners();
  }

  Future<void> setWorkingHoursStart(int value) async {
    _workingHoursStart = value;
    await _prefs.setInt(_keyWorkingHoursStart, value);
    notifyListeners();
  }

  Future<void> setWorkingHoursEnd(int value) async {
    _workingHoursEnd = value;
    await _prefs.setInt(_keyWorkingHoursEnd, value);
    notifyListeners();
  }

  Future<void> setDailyKickstartEnabled(bool value) async {
    _dailyKickstartEnabled = value;
    await _prefs.setBool(_keyDailyKickstartEnabled, value);
    notifyListeners();
  }

  Future<void> setDailyKickstartHour(int value) async {
    _dailyKickstartHour = value;
    await _prefs.setInt(_keyDailyKickstartHour, value);
    notifyListeners();
  }

  Future<void> setDailyKickstartMinute(int value) async {
    _dailyKickstartMinute = value;
    await _prefs.setInt(_keyDailyKickstartMinute, value);
    notifyListeners();
  }

  Future<void> setNotificationsPaused(bool value) async {
    _notificationsPaused = value;
    await _prefs.setBool(_keyNotificationsPaused, value);
    notifyListeners();
  }

  Future<void> setLastUsagePercentage(double value) async {
    _lastUsagePercentage = value;
    await _prefs.setDouble(_keyLastUsagePercentage, value);
    notifyListeners();
  }

  Future<void> setLastResetTime(DateTime? value) async {
    _lastResetTime = value;
    if (value != null) {
      await _prefs.setString(_keyLastResetTime, value.toIso8601String());
    } else {
      await _prefs.remove(_keyLastResetTime);
    }
    notifyListeners();
  }
  
  // Smart timer setters
  Future<void> setWindowStartTime(DateTime? value) async {
    _windowStartTime = value;
    if (value != null) {
      await _prefs.setString(_keyWindowStartTime, value.toIso8601String());
    } else {
      await _prefs.remove(_keyWindowStartTime);
    }
    notifyListeners();
  }
  
  Future<void> setPreResetMinutes(int value) async {
    _preResetMinutes = value;
    await _prefs.setInt(_keyPreResetMinutes, value);
    notifyListeners();
  }
  
  Future<void> setPostResetMinutes(int value) async {
    _postResetMinutes = value;
    await _prefs.setInt(_keyPostResetMinutes, value);
    notifyListeners();
  }
  
  Future<void> setDeadlineEnabled(bool value) async {
    _deadlineEnabled = value;
    await _prefs.setBool(_keyDeadlineEnabled, value);
    notifyListeners();
  }
  
  Future<void> setDeadlineHour(int value) async {
    _deadlineHour = value;
    await _prefs.setInt(_keyDeadlineHour, value);
    notifyListeners();
  }
  
  Future<void> setDeadlineMinutesBefore(int value) async {
    _deadlineMinutesBefore = value;
    await _prefs.setInt(_keyDeadlineMinutesBefore, value);
    notifyListeners();
  }

  bool isWithinWorkingHours(DateTime time) {
    if (!_workingHoursEnabled) return true;
    final hour = time.hour;
    if (_workingHoursStart < _workingHoursEnd) {
      return hour >= _workingHoursStart && hour < _workingHoursEnd;
    } else {
      return hour >= _workingHoursStart || hour < _workingHoursEnd;
    }
  }

  Future<void> clearAllData() async {
    await _prefs.clear();
    _sessionKey = null;
    _organizationId = null;
    _hasCompletedSetup = false;
    _lastUsagePercentage = 0;
    _lastResetTime = null;
    _windowStartTime = null;
    notifyListeners();
  }
}
