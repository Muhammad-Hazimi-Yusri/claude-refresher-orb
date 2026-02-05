# Building iOS with Codemagic (Free)

Build iOS apps from Windows/Linux using Codemagic's cloud Macs.

## Setup Steps

### 1. Push to GitHub

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/claude_usage_alarm.git
git push -u origin main
```

### 2. Connect Codemagic

1. Go to [codemagic.io](https://codemagic.io)
2. Sign up with GitHub
3. Add your repository
4. Select "Flutter App"

### 3. Build Settings

- Platform: iOS
- Mode: Release
- Flutter version: Stable

### 4. Start Build

Click "Start new build" → Wait ~10-15 min → Download .ipa

## Installing on iPhone

### Option A: AltStore (Recommended)

1. Install [AltServer](https://altstore.io) on Windows
2. Install AltStore on your iPhone via USB
3. Transfer .ipa to iPhone
4. Open in AltStore

### Option B: Sideloadly

1. Download [Sideloadly](https://sideloadly.io)
2. Connect iPhone via USB
3. Drag .ipa → Enter Apple ID → Install

## Free Tier Limits

| Resource | Limit |
|----------|-------|
| Build minutes | 500/month |
| Max duration | 120 min |
| Concurrent builds | 1 |

**500 minutes ≈ 30-50 iOS builds per month**
