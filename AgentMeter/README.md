# AgentMeter 📊

**Know what your AI agents actually cost you.**

A tiny macOS menu bar app that tracks AI spending in real-time — per agent, per provider, per session. Built for developers and teams running AI agents.

## Download

📥 **[Download AgentMeter v0.7.0](https://github.com/Real-Pixeldrop/agent-meter/releases/latest)**

1. Download `AgentMeter.zip`
2. Unzip → drag `AgentMeter.app` to `/Applications/`
3. Double-click to launch (lives in menu bar)

## What's New in v0.7.0

- 🔍 **Smart Clawdbot Detection** — Auto-detects Clawdbot from running processes, common paths, or set a custom path in Settings
- 🔄 **Auto-Updater** — Checks for updates on launch, shows a badge in the menu bar, one-click update & relaunch
- 📦 **Proper .app Bundle** — Now ships as a real macOS .app with Info.plist

## Features

- 🎯 **Real-time cost tracking** in your menu bar
- 🤖 **Per-agent breakdown** — see which agent burns the most tokens
- 📊 **Context gauge** — monitor context window usage per session
- 🔐 **OAuth quota tracking** — session & weekly utilization for Claude
- ⚠️ **Budget alerts** — get notified when spending exceeds thresholds
- 💼 **Plan savings calculator** — see your subscription ROI
- 🔌 **Multi-provider** — Anthropic, OpenRouter, OpenAI
- 🌐 **Remote mode** — connect to an AgentMeter server on another machine
- 🔄 **Auto-updates** — never miss a new version

## Supported Providers

| Provider | Status |
|----------|--------|
| Anthropic (Claude) + OpenClaw/Clawdbot | ✅ |
| OpenRouter | ✅ |
| OpenAI | ✅ |

## Clawdbot Detection

AgentMeter automatically detects your Clawdbot installation:

1. **Custom path** — Set in Settings → Clawdbot Path (highest priority)
2. **Process detection** — Finds running `clawdbot` process and extracts config path
3. **Common paths** — Checks `~/.clawdbot/`, `~/.config/clawdbot/`, etc.

No API keys needed when Clawdbot is detected — usage is tracked from local session logs.

## Build from Source

```bash
git clone https://github.com/Real-Pixeldrop/agent-meter.git
cd agent-meter
swift build -c release
# Binary at .build/release/AgentMeter
```

## Stack

- Swift / SwiftUI
- macOS 14+ (Sonoma)
- Menu bar app (no dock icon)
- Local data only — nothing leaves your machine

## License

MIT

## Author

Built by [Pixel Drop](https://pixel-drop.com)
