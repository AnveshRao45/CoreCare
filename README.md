# CoreCare

Privacy-focused Android nutrition app (MSc dissertation artefact). It combines **on-device AI meal planning and chat** with **Health Connect vitals** — prompts and health data stay on the phone after the model is downloaded.

**Use it for:** daily meal ideas, calorie/macro tracking, wearable vitals on one dashboard, and an offline nutrition coach. Not for clinical advice.

## What it does

- **Meal plans** — AI generates a four-meal daily plan (offline after setup)
- **AI chat** — Nutrition coach based on your profile
- **Health Connect** — Steps, heart rate, calories, sleep, water
- **Daily goals** — Calorie and macro tracking
- **Workouts** — Camera rep counting (squats, push-ups, curls)

## Requirements

- Flutter SDK (see `pubspec.yaml`)
- Android phone (recommended over emulator)
- **Health Connect** app installed
- ~2.5 GB free storage for the AI model

## Run the app

```bash
flutter pub get
flutter run
```

Use a **physical Android device** for Health Connect and on-device AI.

## First-time setup in the app

1. Complete onboarding (name, diet, goals, etc.)
2. Download **Gemma 2** from the home screen (~2.15 GB, Wi‑Fi once)
3. Tap **Connect** on vitals and allow Health Connect permissions
4. Generate a meal plan or open **AI Chat**

## Tech stack

| Part | Used for |
|------|----------|
| Flutter / Dart | UI and app logic |
| Hive | Local storage |
| Riverpod | State management |
| llama_flutter_android | On-device AI (Gemma 2) |
| health plugin | Health Connect reads/writes |
| Google ML Kit | Workout pose detection |

## Project layout

```
lib/
  features/          # Screens (home, chat, onboarding, vitals UI)
  providers/         # Riverpod state (LLM, user, health)
  services/          # Health Connect, Hive, nutrition targets, model download
  models/            # User profile, meals, vitals
  utils/             # Meal JSON parser, workout detection
test/                # Unit tests (parser, nutrition targets, widgets)
android/             # Android build + Health Connect native hooks
aimodels/            # Empty in repo — GGUF downloaded on device
```

**Main files:** `lib/main.dart`, `lib/features/home.dart`, `lib/providers/llm_pro.dart`, `lib/services/health_service.dart`, `lib/services/nutrition_targets_service.dart`

## Notes

- Model files (`.gguf`) are **not** in this repo — download inside the app.
- On-device AI is **Android only**; iOS is not supported in this build.
- Meal generation can take several minutes on slower phones.

## Repository

https://github.com/AnveshRao45/CoreCare.git
