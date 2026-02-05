import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/api_service.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';
import 'home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _sessionKeyController = TextEditingController();
  bool _isValidating = false;
  String? _errorMessage;
  bool _obscureText = true;

  @override
  void dispose() {
    _sessionKeyController.dispose();
    super.dispose();
  }

  Future<void> _validateAndSave() async {
    final sessionKey = _sessionKeyController.text.trim();
    
    if (sessionKey.isEmpty) {
      setState(() => _errorMessage = 'Please enter your session key.');
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
    });

    final api = context.read<ApiService>();
    final settings = context.read<SettingsService>();
    final result = await api.fetchOrganizations(sessionKey: sessionKey);

    if (!mounted) return;

    setState(() => _isValidating = false);

    if (result.isSuccess && result.data != null && result.data!.isNotEmpty) {
      final org = result.data!.first;
      await settings.setSessionKey(sessionKey);
      await settings.setOrganizationId(org.uuid);
      await settings.setHasCompletedSetup(true);

      final notifications = context.read<NotificationService>();
      await notifications.requestPermissions();

      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      setState(() => _errorMessage = result.errorMessage ?? 'Invalid session key.');
    }
  }

  void _skipSetup() async {
    final settings = context.read<SettingsService>();
    await settings.setHasCompletedSetup(true);

    final notifications = context.read<NotificationService>();
    await notifications.requestPermissions();

    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup'),
        actions: [TextButton(onPressed: _skipSetup, child: const Text('Skip'))],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.notifications_active, size: 80, color: Color(0xFFDA7756)),
            const SizedBox(height: 16),
            Text(
              'Welcome to\nClaude Usage Alarm',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Get notified when your Claude usage limit resets',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // API Mode Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.sync, color: Color(0xFFDA7756)),
                      const SizedBox(width: 8),
                      Text('API Mode (Recommended)', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),
                    const Text('Automatically track your actual usage and get precise reset notifications.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _sessionKeyController,
                      obscureText: _obscureText,
                      decoration: InputDecoration(
                        labelText: 'Session Key',
                        hintText: 'sk-ant-sid01-...',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureText = !_obscureText),
                        ),
                      ),
                      autocorrect: false,
                      enableSuggestions: false,
                    ),

                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(_errorMessage!, style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12)),
                    ],

                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: () => _showHelpDialog(context),
                      icon: const Icon(Icons.help_outline, size: 18),
                      label: const Text('How to get session key'),
                    ),
                    const SizedBox(height: 16),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _isValidating ? null : _validateAndSave,
                        child: _isValidating
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Text('Connect'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Row(children: [
              Expanded(child: Divider()),
              Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text('or', style: TextStyle(color: Colors.grey))),
              Expanded(child: Divider()),
            ]),
            const SizedBox(height: 16),

            // Manual Mode Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.timer, color: Colors.orange),
                      const SizedBox(width: 8),
                      Text('Manual Timer Mode', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ]),
                    const SizedBox(height: 8),
                    const Text('No setup required. Just tap "Start Timer" when you begin using Claude.', style: TextStyle(color: Colors.grey)),
                    const SizedBox(height: 16),
                    SizedBox(width: double.infinity, child: OutlinedButton(onPressed: _skipSetup, child: const Text('Use Manual Mode'))),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('How to Get Session Key', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),
              _buildStep(1, 'Open claude.ai in a desktop browser and log in'),
              _buildStep(2, 'Open Developer Tools (press F12 or Cmd+Option+I)'),
              _buildStep(3, 'Go to the Network tab'),
              _buildStep(4, 'Refresh the page'),
              _buildStep(5, 'Click on any request (e.g., "usage")'),
              _buildStep(6, 'Look in Headers → Cookie'),
              _buildStep(7, 'Find "sessionKey=sk-ant-sid01-..."'),
              _buildStep(8, 'Copy the value (starts with sk-ant-sid01-)'),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [Icon(Icons.security, color: Colors.green), SizedBox(width: 8), Text('Security', style: TextStyle(fontWeight: FontWeight.bold))]),
                    SizedBox(height: 8),
                    Text('Your session key is stored securely and never leaves your device.', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28, height: 28,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary, shape: BoxShape.circle),
            child: Center(child: Text('$number', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
        ],
      ),
    );
  }
}
