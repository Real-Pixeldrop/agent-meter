# AgentMeter - Brief Projet

## Concept
Menu bar app macOS qui affiche en temps reel le cout de tes agents IA, par projet et par client.

## Probleme
Tu paies des APIs IA (Anthropic, OpenAI, OpenRouter) mais tu sais jamais combien chaque agent/projet/client te coute. Tu decouvres la facture a la fin du mois.

## Solution
Une petite icone dans la menu bar qui montre :
- Le cout total du jour/semaine/mois
- Le cout ventile par agent (Claudia, Mike, Valentina, Clea...)
- Le cout ventile par client/projet
- Une alerte si un seuil est depasse

## MVP (v0.1)
- Menu bar icon avec le cout du jour en direct
- Connexion API Anthropic (usage endpoint)
- Connexion API OpenRouter (usage endpoint)
- Liste des couts par agent dans le dropdown
- Graphe simple des 7 derniers jours

## Stack
- **Electron + React** (rapide a shipper, Akli maitrise le web)
- Ou **Swift + SwiftUI** (natif, plus pro, plus leger)
- Recommandation : Electron pour le MVP, migration Swift si ca prend

## APIs a connecter (MVP)
1. **Anthropic** : https://api.anthropic.com/v1/usage (ou scrape du dashboard)
2. **OpenRouter** : https://openrouter.ai/api/v1/auth/key (donne le credit restant)
3. **Clawdbot logs** : parser les logs locaux pour ventiler par agent

## APIs futures (v0.2+)
- OpenAI
- Google AI (Gemini)
- Pennylane (pour mapper cout IA <-> facturation client)
- Alertes Telegram/iMessage si seuil depasse

## Differentiation vs CodexBar
- CodexBar = quotas/limites pour devs (session limits, rate limits)
- AgentMeter = COUTS REELS par projet/client pour freelances/agences
- Angle business, pas angle dev
- Vue par client : "Ce client me coute X€/mois en IA"

## Nom
AgentMeter (ou agent-meter)

## Repo
github.com/Real-Pixeldrop/agent-meter
