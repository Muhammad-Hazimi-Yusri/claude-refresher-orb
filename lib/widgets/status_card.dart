import 'package:flutter/material.dart';
import '../models/usage_data.dart';

class StatusCard extends StatelessWidget {
  final UsageData? usageData;
  final DateTime? manualTimerEndTime;

  const StatusCard({super.key, this.usageData, this.manualTimerEndTime});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          if (usageData?.fiveHour != null) ...[
            _buildRow(context, icon: Icons.access_time, label: 'Resets', value: usageData!.fiveHour!.formattedResetTime),
            const SizedBox(height: 12),
            _buildRow(context, icon: Icons.hourglass_bottom, label: 'Time Left', value: usageData!.fiveHour!.formattedTimeRemaining, valueColor: Colors.green),
          ] else if (manualTimerEndTime != null) ...[
            _buildRow(context, icon: Icons.timer, label: 'Timer Ends', value: _formatDateTime(manualTimerEndTime!)),
            const SizedBox(height: 12),
            _buildRow(context, icon: Icons.hourglass_bottom, label: 'Time Left', value: _formatTimeRemaining(manualTimerEndTime!), valueColor: Colors.blue),
          ] else
            _buildRow(context, icon: Icons.info_outline, label: 'Status', value: 'No active tracking', valueColor: Colors.grey),
        ],
      ),
    );
  }

  Widget _buildRow(BuildContext context, {required IconData icon, required String label, required String value, Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: Colors.grey[600])),
        const Spacer(),
        Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final date = DateTime(dateTime.year, dateTime.month, dateTime.day);
    final timeStr = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    if (date == today) return 'Today $timeStr';
    if (date == tomorrow) return 'Tomorrow $timeStr';
    return '${dateTime.day}/${dateTime.month} $timeStr';
  }

  String _formatTimeRemaining(DateTime endTime) {
    final remaining = endTime.difference(DateTime.now());
    if (remaining.isNegative) return 'Done!';
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    if (hours > 0) return '${hours}h ${minutes}m left';
    return '${minutes}m left';
  }
}
