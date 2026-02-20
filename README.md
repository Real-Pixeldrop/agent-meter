# Agent Meter

Suivez le coût réel de vos agents IA par projet et par client. Menu bar macOS.

## Download

[Télécharger AgentMeter.zip](https://github.com/Real-Pixeldrop/agent-meter/releases/latest/download/AgentMeter.zip)

1. Télécharge le zip
2. Dézipe
3. Glisse dans Applications
4. Double-clic. C'est prêt.

## Comment ça marche

1. **Ajoute** tes providers IA (OpenAI, Anthropic, etc.)
2. **Configure** tes projets et clients
3. **Consulte** les coûts en temps réel depuis la menu bar
4. **Analyse** les dépenses par agent, projet ou client

## From source

```bash
git clone https://github.com/Real-Pixeldrop/agent-meter.git
cd agent-meter
swift build -c release
cp -r .build/release/AgentMeter.app /Applications/ 2>/dev/null || \
  cp .build/release/AgentMeter /Applications/
```

## One-liner install

```bash
curl -sL https://github.com/Real-Pixeldrop/agent-meter/releases/latest/download/AgentMeter.zip -o /tmp/am.zip && unzip -o /tmp/am.zip -d /Applications/ && xattr -cr /Applications/AgentMeter.app && open /Applications/AgentMeter.app
```
