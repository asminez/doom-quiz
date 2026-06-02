# DoomQuiz

Native **SwiftUI iOS** app that limits distracting apps (Screen Time / Family Controls) and unlocks more scroll time when you pass a syllabus quiz.

## Features

- **Focus** — Unrot-style dark UI, daily minute budget, Screen Time app shields
- **Study** — Quizlet-style memorize cards (7–8 points) + 5 gate questions from syllabus/topic
- **Gate quiz** — When out of minutes: 5/5 → +10 min, 4/5 → +5, 3/5 → +2, else none
- **AI** — Same **Cloudflare Worker** as AIwidget → OpenRouter `deepseek/deepseek-v4-flash` (no local API needed)

## Run (iOS)

```bash
open ios/DoomQuiz.xcodeproj
```

Select an iPhone simulator or device → **Run** (⌘R).

In the app: **Authorize Screen Time** → **Choose apps to shield** → create a deck on **Study**.

## AI / Worker

DoomQuiz calls the same worker as Dailyflow/AIwidget:

| Setting | Value |
|---------|--------|
| URL | `https://habitmap.asminrijal289-f9b.workers.dev` |
| Header | `X-Dailyflow-Key` (Worker `CLIENT_SECRET`) |
| Body | OpenAI-style `{ "messages": [...], "max_tokens": 1200 }` |

Configured in `ios/DoomQuiz/Services/WorkerConfig.swift` — same pattern as AIwidget `BridgeConfig.swift`. The OpenRouter key stays in Cloudflare (`DEEPSEEK` secret); the app never sees it.

The `server/` folder is an **optional local dev proxy** only; production uses the worker.

## Project layout

| Path | Purpose |
|------|---------|
| `ios/DoomQuiz/` | SwiftUI app + Family Controls |
| `server/` | Optional local OpenRouter proxy (not required) |

## Requirements

- Xcode 16+ / iOS 17+ simulator or device
- Apple Developer **Family Controls** capability on device builds
- Cloudflare Worker deployed with `DEEPSEEK` + optional `CLIENT_SECRET`
