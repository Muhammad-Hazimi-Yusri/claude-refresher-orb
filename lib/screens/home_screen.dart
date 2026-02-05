import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/usage_data.dart';
import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import '../widgets/usage_circle.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  UsageData? _usageData;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  Timer? _refreshTimer;
  Timer? _autoSyncTimer;
  DateTime? _lastSyncTime;

  @override
  void initState() {
    super.initState();
    _startRefreshTimer();
    // Auto-sync on startup if API configured
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoSyncIfConfigured();
      _startAutoSyncTimer();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  void _startRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  void _startAutoSyncTimer() {
    // Auto-sync every 5 minutes
    _autoSyncTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      final settings = context.read<SettingsService>();
      if (settings.hasCredentials && !_isLoading) {
        print('[Auto-sync] Syncing with API...');
        _fetchUsage(showSuccessMessage: false);
      }
    });
  }

  Future<void> _autoSyncIfConfigured() async {
    final settings = context.read<SettingsService>();
    if (settings.hasCredentials) {
      await _fetchUsage();
    }
  }

  Future<void> _fetchUsage({bool showSuccessMessage = true}) async {
    final settings = context.read<SettingsService>();
    final api = context.read<ApiService>();
    final notifications = context.read<NotificationService>();

    if (!settings.hasCredentials) {
      setState(() {
        _errorMessage = 'No API credentials. Go to Settings to add your session key.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      if (showSuccessMessage) _successMessage = null;
    });

    try {
      final result = await api.fetchUsage(
        organizationId: settings.organizationId!,
        sessionKey: settings.sessionKey!,
      );

      if (!mounted) return;

      if (result.isSuccess && result.data != null) {
        final data = result.data!;
        _lastSyncTime = DateTime.now();
        
        setState(() {
          _isLoading = false;
          _usageData = data;
          _errorMessage = null;
        });

        // Save and schedule notifications if we have 5-hour data
        if (data.fiveHour != null) {
          await settings.setLastUsagePercentage(data.fiveHour!.percentage);
          
          if (data.fiveHour!.resetsAt != null) {
            await settings.setLastResetTime(data.fiveHour!.resetsAt);
            
            // Schedule notifications based on API reset time
            if (!settings.notificationsPaused) {
              final resetTime = data.fiveHour!.resetsAt!;
              try {
                await notifications.scheduleSmartNotifications(
                  startTime: resetTime.subtract(const Duration(hours: 5)),
                  preResetMinutes: settings.preResetMinutes,
                  postResetMinutes: settings.postResetMinutes,
                  deadlineHour: settings.deadlineEnabled ? settings.deadlineHour : null,
                  deadlineMinutesBefore: settings.deadlineMinutesBefore,
                );
              } catch (e) {
                print('[Notification] Error scheduling: $e');
              }
            }
          }
          
          if (showSuccessMessage) {
            setState(() {
              _successMessage = 'Synced! ${data.fiveHour!.percentage.round()}% used, resets ${data.fiveHour!.formattedResetTime}';
            });
          }
        } else {
          if (showSuccessMessage) {
            setState(() {
              _successMessage = 'Synced! No active usage window.';
            });
          }
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage = result.errorMessage ?? result.error?.defaultMessage ?? 'Unknown API error';
          _successMessage = null;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error: $e';
        _successMessage = null;
      });
    }
  }

  void _startManualWindow() async {
    final settings = context.read<SettingsService>();
    final notifications = context.read<NotificationService>();
    
    final startTime = DateTime.now();
    await settings.setWindowStartTime(startTime);
    
    if (!settings.notificationsPaused) {
      await notifications.scheduleSmartNotifications(
        startTime: startTime,
        preResetMinutes: settings.preResetMinutes,
        postResetMinutes: settings.postResetMinutes,
        deadlineHour: settings.deadlineEnabled ? settings.deadlineHour : null,
        deadlineMinutesBefore: settings.deadlineMinutesBefore,
      );
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Window started! Resets at ${_formatTime(startTime.add(const Duration(hours: 5)))}'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
      ),
    );
  }

  void _cancelManualWindow() async {
    final settings = context.read<SettingsService>();
    final notifications = context.read<NotificationService>();
    
    await settings.setWindowStartTime(null);
    await notifications.cancelAllUsageNotifications();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Window tracking cancelled.'), behavior: SnackBarBehavior.floating),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;
    if (hours > 0) return '${hours}h ${minutes}m ${seconds}s';
    if (minutes > 0) return '${minutes}m ${seconds}s';
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();
    final hasApiData = _usageData?.fiveHour != null;
    final hasManualWindow = settings.isWindowActive;
    
    // Determine what percentage to show
    double displayPercentage = 0;
    if (hasApiData) {
      displayPercentage = _usageData!.fiveHour!.percentage;
    } else if (settings.lastUsagePercentage > 0) {
      displayPercentage = settings.lastUsagePercentage;
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claude Usage'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchUsage,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Usage Circle
              UsageCircle(
                percentage: displayPercentage,
                isLoading: _isLoading,
              ),
              const SizedBox(height: 24),

              // Success Message
              if (_successMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_successMessage!, style: const TextStyle(color: Colors.green))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Theme.of(context).colorScheme.error),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // API Status Card (if we have API data)
              if (hasApiData) _buildApiStatusCard(_usageData!.fiveHour!),
              
              // Manual Window Card (if no API data but manual window active)
              if (!hasApiData && hasManualWindow) _buildManualWindowCard(settings),
              
              // No Active Window Card
              if (!hasApiData && !hasManualWindow) _buildNoWindowCard(),

              const SizedBox(height: 16),

              // Action Buttons
              _buildActionButtons(settings, hasApiData),
              const SizedBox(height: 16),

              // Notification Settings Summary
              _buildNotificationStatus(settings),
              
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildApiStatusCard(LimitData data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.cloud_done, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              Text(
                'API Connected',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
              const Spacer(),
              if (_lastSyncTime != null)
                Text(
                  'Synced ${_formatTime(_lastSyncTime!)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusRow(Icons.percent, 'Usage', '${data.percentage.round()}%'),
          const SizedBox(height: 8),
          _buildStatusRow(Icons.schedule, 'Resets', data.formattedResetTime),
          const SizedBox(height: 8),
          _buildStatusRow(
            Icons.hourglass_bottom,
            'Time Left',
            data.formattedTimeRemaining,
            valueColor: Colors.green,
          ),
          const SizedBox(height: 8),
          Text(
            'Auto-syncs every 5 minutes',
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildManualWindowCard(SettingsService settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.5), width: 2),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.timer, color: Colors.orange, size: 28),
              const SizedBox(width: 12),
              Text(
                'Manual Timer Active',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatusRow(Icons.login, 'Started', _formatTime(settings.windowStartTime!)),
          const SizedBox(height: 8),
          _buildStatusRow(Icons.logout, 'Resets', _formatTime(settings.windowResetTime!)),
          const SizedBox(height: 8),
          _buildStatusRow(
            Icons.hourglass_bottom,
            'Time Left',
            _formatDuration(settings.timeUntilReset!),
            valueColor: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildNoWindowCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.pause_circle_outline, color: Colors.grey[400], size: 28),
              const SizedBox(width: 12),
              Text(
                'No Active Window',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Use "Sync with API" to fetch your real usage, or "Start Manual Timer" to track manually.',
            style: TextStyle(color: Colors.grey[600], fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusRow(IconData icon, String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[600])),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }

  Widget _buildActionButtons(SettingsService settings, bool hasApiData) {
    final hasManualWindow = settings.isWindowActive;
    
    return Column(
      children: [
        // Primary: Sync with API (if credentials configured)
        if (settings.hasCredentials)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _fetchUsage,
              icon: _isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.sync),
              label: Text(_isLoading ? 'Syncing...' : 'Sync with API'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.blue,
              ),
            ),
          ),
        
        if (settings.hasCredentials) const SizedBox(height: 12),
        
        // Secondary: Manual timer (only if no API data)
        if (!hasApiData)
          SizedBox(
            width: double.infinity,
            child: hasManualWindow
                ? OutlinedButton.icon(
                    onPressed: _cancelManualWindow,
                    icon: const Icon(Icons.stop, color: Colors.red),
                    label: const Text('Cancel Manual Timer', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: _startManualWindow,
                    icon: const Icon(Icons.timer, color: Colors.orange),
                    label: const Text('Start Manual Timer', style: TextStyle(color: Colors.orange)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
          ),
        
        // If no credentials, show setup prompt
        if (!settings.hasCredentials) ...[
          const SizedBox(height: 8),
          Text(
            'Go to Settings → Session Key to enable API sync',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildNotificationStatus(SettingsService settings) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Notifications', style: Theme.of(context).textTheme.titleMedium),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (settings.notificationsPaused ? Colors.orange : Colors.green).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      settings.notificationsPaused ? Icons.notifications_off : Icons.notifications_active,
                      size: 14,
                      color: settings.notificationsPaused ? Colors.orange : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      settings.notificationsPaused ? 'Paused' : 'Active',
                      style: TextStyle(color: settings.notificationsPaused ? Colors.orange : Colors.green, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildSettingRow(Icons.alarm, 'Pre-reset alert', '${settings.preResetMinutes} min before'),
          const SizedBox(height: 4),
          _buildSettingRow(Icons.celebration, 'Reset alert', '${settings.postResetMinutes} min after'),
          if (settings.deadlineEnabled) ...[
            const SizedBox(height: 4),
            _buildSettingRow(Icons.schedule, 'Deadline reminder', 'Before ${settings.deadlineDescription}'),
          ],
        ],
      ),
    );
  }

  Widget _buildSettingRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
