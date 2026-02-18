# AgentMeter 📊

**Know what your AI agents actually cost you.**

A tiny macOS menu bar app that tracks AI spending in real-time — per agent, per project, per client. Built for freelancers and agencies running multiple AI agents.

## Why

You're running AI agents (Claude, GPT, Gemini...) across multiple projects and clients. But you have no idea what each one costs until the invoice hits. AgentMeter fixes that.

## Features

- 🎯 **Real-time cost tracking** in your menu bar
- 🤖 **Per-agent breakdown** — see which agent burns the most tokens
- 💼 **Per-client view** — know exactly what each client costs you in AI
- 📈 **7-day graph** — spot trends before they become problems
- ⚠️ **Budget alerts** — get notified when spending exceeds thresholds
- 🔌 **Multi-provider** — Anthropic, OpenRouter, OpenAI, Google AI

## Supported Providers

| Provider | Status |
|----------|--------|
| Anthropic (Claude) | ✅ |
| OpenRouter | ✅ |
| OpenAI | 🔜 |
| Google AI (Gemini) | 🔜 |

## Install

```bash
# Coming soon
brew install --cask real-pixeldrop/tap/agent-meter
```

## Screenshots

*Coming soon*

## How It Works

AgentMeter reads usage data from your AI provider APIs and local agent logs. It aggregates costs by agent, project, and client — then displays it in a clean menu bar dropdown.

No data leaves your machine. Everything runs locally.

## Stack

- Electron + React
- Local SQLite for history
- Provider APIs for usage data

## License

MIT

## Author

Built by [Mr Pixel](https://github.com/Real-Pixeldrop) @ [Pixel Drop](https://pixel-drop.com)
