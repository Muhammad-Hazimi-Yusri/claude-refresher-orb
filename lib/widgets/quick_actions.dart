import 'package:flutter/material.dart';

class QuickActions extends StatelessWidget {
  final bool isLoading;
  final bool hasCredentials;
  final bool manualTimerActive;
  final VoidCallback onRefresh;
  final VoidCallback onStartTimer;
  final VoidCallback onCancelTimer;

  const QuickActions({
    super.key,
    required this.isLoading,
    required this.hasCredentials,
    required this.manualTimerActive,
    required this.onRefresh,
    required this.onStartTimer,
    required this.onCancelTimer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (hasCredentials)
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isLoading ? null : onRefresh,
              icon: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.refresh),
              label: Text(isLoading ? 'Refreshing...' : 'Refresh Usage'),
            ),
          ),
        if (hasCredentials) const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: manualTimerActive
              ? OutlinedButton.icon(
                  onPressed: onCancelTimer,
                  icon: const Icon(Icons.cancel, color: Colors.red),
                  label: const Text('Cancel Timer', style: TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.red)),
                )
              : OutlinedButton.icon(
                  onPressed: onStartTimer,
                  icon: const Icon(Icons.timer),
                  label: const Text('Start 5h Timer'),
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.orange, side: const BorderSide(color: Colors.orange)),
                ),
        ),
      ],
    );
  }
}
