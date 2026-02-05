import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import 'setup_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsService>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          // Smart Timer Settings
          _buildSectionHeader(context, 'Smart Timer'),
          
          ListTile(
            title: const Text('Pre-reset alert'),
            subtitle: Text('${settings.preResetMinutes} minutes before reset'),
            leading: const Icon(Icons.alarm),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMinutesPicker(context, settings, isPreReset: true),
          ),
          
          ListTile(
            title: const Text('Post-reset alert'),
            subtitle: Text('${settings.postResetMinutes} minutes after reset'),
            leading: const Icon(Icons.celebration),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showMinutesPicker(context, settings, isPreReset: false),
          ),
          
          SwitchListTile(
            title: const Text('Deadline reminder'),
            subtitle: Text(settings.deadlineEnabled 
                ? 'Remind before ${settings.deadlineDescription}'
                : 'No deadline reminder'),
            value: settings.deadlineEnabled,
            onChanged: (value) => settings.setDeadlineEnabled(value),
            secondary: const Icon(Icons.schedule),
          ),
          
          if (settings.deadlineEnabled)
            ListTile(
              title: const Text('Deadline hour'),
              subtitle: Text(settings.deadlineDescription),
              leading: const SizedBox(width: 24),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showDeadlineHourPicker(context, settings),
            ),
          
          const Divider(),
          
          // Notifications Section
          _buildSectionHeader(context, 'Notifications'),
          
          SwitchListTile(
            title: const Text('Pause All Notifications'),
            subtitle: const Text('Temporarily disable all alarms'),
            value: settings.notificationsPaused,
            onChanged: (value) async {
              await settings.setNotificationsPaused(value);
              if (value) context.read<NotificationService>().cancelAll();
            },
            secondary: Icon(settings.notificationsPaused ? Icons.notifications_off : Icons.notifications_active,
                color: settings.notificationsPaused ? Colors.orange : null),
          ),

          SwitchListTile(
            title: const Text('Daily Kickstart Alarm'),
            subtitle: Text(settings.dailyKickstartEnabled
                ? 'Reminds you at ${settings.dailyKickstartDescription}'
                : 'Morning reminder to start window'),
            value: settings.dailyKickstartEnabled,
            onChanged: settings.notificationsPaused ? null : (value) async {
              await settings.setDailyKickstartEnabled(value);
              final notifications = context.read<NotificationService>();
              if (value) {
                notifications.scheduleDailyKickstart(settings.dailyKickstartHour, settings.dailyKickstartMinute);
              } else {
                notifications.cancelDailyKickstart();
              }
            },
            secondary: const Icon(Icons.wb_sunny),
          ),

          if (settings.dailyKickstartEnabled)
            ListTile(
              title: const Text('Kickstart Time'),
              subtitle: Text(settings.dailyKickstartDescription),
              leading: const SizedBox(width: 24),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showTimePicker(context, settings),
            ),

          const Divider(),
          
          // Working Hours Section
          _buildSectionHeader(context, 'Working Hours'),

          SwitchListTile(
            title: const Text('Working Hours Only'),
            subtitle: Text(settings.workingHoursEnabled
                ? 'Notifications only during ${settings.workingHoursDescription}'
                : 'Receive notifications anytime'),
            value: settings.workingHoursEnabled,
            onChanged: (value) => settings.setWorkingHoursEnabled(value),
            secondary: const Icon(Icons.work),
          ),

          if (settings.workingHoursEnabled) ...[
            ListTile(
              title: const Text('Start Time'),
              subtitle: Text('${settings.workingHoursStart.toString().padLeft(2, '0')}:00'),
              leading: const SizedBox(width: 24),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showHourPicker(context, settings, isStart: true),
            ),
            ListTile(
              title: const Text('End Time'),
              subtitle: Text(settings.workingHoursEnd == 24 ? '00:00 (midnight)' : '${settings.workingHoursEnd.toString().padLeft(2, '0')}:00'),
              leading: const SizedBox(width: 24),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => _showHourPicker(context, settings, isStart: false),
            ),
          ],

          const Divider(),
          
          // Account Section
          _buildSectionHeader(context, 'API Mode (Optional)'),

          ListTile(
            title: const Text('Session Key'),
            subtitle: Text(settings.hasCredentials ? 'Configured ✓' : 'Not configured'),
            leading: const Icon(Icons.key),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showUpdateSessionKey(context),
          ),
          
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 18, color: Colors.blue),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'API mode only works on desktop/mobile builds, not in browser due to CORS restrictions.',
                    style: TextStyle(fontSize: 12, color: Colors.blue),
                  ),
                ),
              ],
            ),
          ),

          const Divider(),
          
          // About Section
          _buildSectionHeader(context, 'About'),

          const ListTile(title: Text('Version'), subtitle: Text('1.0.0'), leading: Icon(Icons.info_outline)),
          const ListTile(title: Text('Original Project'), subtitle: Text('Usage4Claude by f-is-h'), leading: Icon(Icons.favorite, color: Colors.red)),

          ListTile(
            title: const Text('Test Notification'),
            subtitle: const Text('Verify notifications are working'),
            leading: const Icon(Icons.bug_report),
            onTap: () {
              context.read<NotificationService>().showTestNotification();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Test notification sent!'), behavior: SnackBarBehavior.floating));
            },
          ),

          const Divider(),
          
          // Data Section
          _buildSectionHeader(context, 'Data'),

          ListTile(
            title: const Text('Clear All Data'),
            subtitle: const Text('Remove credentials and reset settings'),
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            onTap: () => _showClearDataDialog(context, settings),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
    );
  }

  void _showMinutesPicker(BuildContext context, SettingsService settings, {required bool isPreReset}) {
    final currentValue = isPreReset ? settings.preResetMinutes : settings.postResetMinutes;
    final options = [1, 2, 3, 5, 10, 15, 20, 30];
    
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isPreReset ? 'Minutes Before Reset' : 'Minutes After Reset', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: options.map((mins) => ChoiceChip(
                label: Text('$mins min'),
                selected: currentValue == mins,
                onSelected: (_) {
                  if (isPreReset) {
                    settings.setPreResetMinutes(mins);
                  } else {
                    settings.setPostResetMinutes(mins);
                  }
                  Navigator.pop(context);
                },
              )).toList(),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDeadlineHourPicker(BuildContext context, SettingsService settings) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Deadline Hour', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('Get a reminder if your window resets before this time', style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: 24,
                itemBuilder: (context, hour) {
                  final label = '${hour.toString().padLeft(2, '0')}:00';
                  final description = hour == 12 ? ' (noon)' : hour == 18 ? ' (evening)' : hour == 0 ? ' (midnight)' : '';
                  return ListTile(
                    title: Text('$label$description'),
                    trailing: settings.deadlineHour == hour ? const Icon(Icons.check, color: Colors.green) : null,
                    onTap: () {
                      settings.setDeadlineHour(hour);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimePicker(BuildContext context, SettingsService settings) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.dailyKickstartHour, minute: settings.dailyKickstartMinute),
    );
    if (time != null) {
      await settings.setDailyKickstartHour(time.hour);
      await settings.setDailyKickstartMinute(time.minute);
      if (settings.dailyKickstartEnabled) {
        context.read<NotificationService>().scheduleDailyKickstart(time.hour, time.minute);
      }
    }
  }

  void _showHourPicker(BuildContext context, SettingsService settings, {required bool isStart}) {
    final currentValue = isStart ? settings.workingHoursStart : settings.workingHoursEnd;
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isStart ? 'Start Time' : 'End Time', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: isStart ? 24 : 25,
                itemBuilder: (context, index) {
                  final hour = index;
                  final displayHour = hour == 24 ? 0 : hour;
                  final label = hour == 24 ? '00:00 (midnight)' : '${displayHour.toString().padLeft(2, '0')}:00';
                  return ListTile(
                    title: Text(label),
                    trailing: currentValue == hour ? const Icon(Icons.check, color: Colors.green) : null,
                    onTap: () {
                      if (isStart) settings.setWorkingHoursStart(hour); else settings.setWorkingHoursEnd(hour);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showUpdateSessionKey(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setState) {
          bool isLoading = false;
          String? error;
          return AlertDialog(
            title: const Text('Update Session Key'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: controller, decoration: InputDecoration(labelText: 'Session Key', hintText: 'sk-ant-sid01-...', errorText: error), obscureText: true),
                const SizedBox(height: 8),
                const Text('Get this from browser dev tools when logged into claude.ai', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
              FilledButton(
                onPressed: isLoading ? null : () async {
                  if (controller.text.isEmpty) { setState(() => error = 'Please enter session key'); return; }
                  setState(() { isLoading = true; error = null; });
                  final api = dialogContext.read<ApiService>();
                  final settings = dialogContext.read<SettingsService>();
                  final result = await api.fetchOrganizations(sessionKey: controller.text.trim());
                  if (result.isSuccess && result.data!.isNotEmpty) {
                    await settings.setSessionKey(controller.text.trim());
                    await settings.setOrganizationId(result.data!.first.uuid);
                    Navigator.pop(dialogContext);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session key updated!'), behavior: SnackBarBehavior.floating));
                  } else {
                    setState(() { isLoading = false; error = result.errorMessage ?? 'Invalid session key'; });
                  }
                },
                child: isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showClearDataDialog(BuildContext context, SettingsService settings) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text('This will remove your session key and reset all settings. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await settings.clearAllData();
              await dialogContext.read<NotificationService>().cancelAll();
              Navigator.pop(dialogContext);
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const SetupScreen()), (route) => false);
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
