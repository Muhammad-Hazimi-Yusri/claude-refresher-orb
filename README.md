# Claude Usage Alarm (Flutter)

Cross-platform app to track Claude AI usage limits with smart alarms.

## Features

- 🔔 **Reset Alarms** - Get notified when your 5-hour window resets
- ⏰ **Daily Kickstart** - Morning reminder to start your usage window
- 🌙 **Working Hours** - Only receive notifications during active hours
- ⏱️ **Manual Timer** - Simple 5-hour countdown mode
- 📊 **Usage Display** - See current usage percentage

## Quick Start (Windows)

```powershell
# Install Flutter (using Chocolatey)
choco install flutter -y

# Verify
flutter doctor

# Run the app
cd claude_usage_alarm
flutter pub get
flutter run -d chrome    # Browser
flutter run -d windows   # Windows desktop
```

## Quick Start (Linux)

```bash
# Install Flutter
sudo snap install flutter --classic

# Verify
flutter doctor

# Run the app
cd claude_usage_alarm
flutter pub get
flutter run -d linux    # Linux desktop
flutter run -d chrome   # Browser
```

## Building for iOS

Use [Codemagic](https://codemagic.io) (free tier: 500 min/month):

1. Push code to GitHub
2. Connect repo to Codemagic
3. Build → Download .ipa
4. Sideload via AltStore

See [CODEMAGIC_SETUP.md](CODEMAGIC_SETUP.md) for details.

## Project Structure

```
lib/
├── main.dart
├── models/usage_data.dart
├── services/
│   ├── api_service.dart
│   ├── settings_service.dart
│   └── notification_service.dart
├── screens/
│   ├── home_screen.dart
│   ├── setup_screen.dart
│   └── settings_screen.dart
└── widgets/
    ├── usage_circle.dart
    ├── status_card.dart
    └── quick_actions.dart
```

## Credits

API code adapted from [Usage4Claude](https://github.com/f-is-h/Usage4Claude) by [@f-is-h](https://github.com/f-is-h).

## License

MIT License - See [LICENSE](LICENSE)
