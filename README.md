# SnapDog 🐶🧩

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Tests](https://img.shields.io/badge/Tests-233%20Passing-brightgreen.svg)]()
[![License](https://img.shields.io/badge/License-Private-lightgrey.svg)]()

> A cozy, dog-themed casual logic puzzle game inspired by Star Battle. Place adorable clay pups on colorful park regions while following classic constraint rules.

---

## 📖 Table of Contents

- [Overview](#-overview)
- [Game Rules](#-game-rules)
- [How to Play & Controls](#-how-to-play--controls)
- [Key Features](#-key-features)
- [Puzzle Intelligence System](#-puzzle-intelligence-system)
- [Game Modes & Progression](#-game-modes--progression)
- [Project Architecture](#-project-architecture)
- [Dog Avatars & Breeds](#-dog-avatars--breeds)
- [Getting Started](#-getting-started)
- [Running Tests & Quality Assurance](#-running-tests--quality-assurance)

---

## 🌟 Overview

**SnapDog** combines the strategic depth of classic grid constraint puzzles (similar to *Star Battle* / *Two Not Touch*) with a warm, playful aesthetic. Players arrange 10 non-touching dogs on a $10 \times 10$ board divided into 10 distinct colored regions.

The game features handcrafted opening levels, endless procedural level generation, a 3-tier progressive deduction hint system, daily challenges with calendar milestones, and calendar-day streak tracking.

---

## 🎯 Game Rules

Every puzzle is played on a $10 \times 10$ grid divided into 10 colored regions. A puzzle is successfully solved when all four core rules are satisfied:

1. **One Dog per Row**: Every row must contain exactly one dog.
2. **One Dog per Column**: Every column must contain exactly one dog.
3. **One Dog per Region**: Every colored territory must contain exactly one dog.
4. **No Touching**: Dogs cannot touch each other orthogonally or diagonally (no two dogs in any $2 \times 2$ area or adjacent cells).

```
   ┌───┬───┬───┐
   │ 🐶│ ❌│ ❌│  <- Dog placed
   ├───┼───┼───┤
   │ ❌│ ❌│ ❌│  <- Diagonal & orthogonal neighbors forbidden
   ├───┼───┼───┤
   │ ❌│ ❌│ 🐶│
   └───┴───┴───┘
```

---

## 🎮 How to Play & Controls

SnapDog is optimized for smooth, tactile mobile gameplay:

- **Single Tap**: Mark a cell with an `×` (cross) to indicate a dog cannot go there. Tap again to clear the cross.
- **Double Tap**: Place and lock a dog into a cell. If an `×` is already on the cell, a double tap instantly replaces it with a dog.
- **Drag-to-Cross**: Swipe across multiple cells in a single continuous gesture to rapidly add or remove `×` marks.
- **Undo Button**: Step backwards through actions, including both dog placements and cross mark edits.
- **Reset Board**: Clear active placements and crosses to start fresh on the current level.
- **Mistake Feedback**: Conflicting dogs and rule violations are temporarily highlighted with gentle tactile bloops, preserving board size and position.

---

## ✨ Key Features

- **Endless Level Progression**: Handcrafted levels 1–9 introduce core mechanics, followed by procedurally generated levels (Level 10 onwards) with no arbitrary cap.
- **3-Tier Progressive Hint System**: Instead of spoiling answers, hints guide players logically through Constraint Guidance $\rightarrow$ Elimination Rationale $\rightarrow$ Forced Placement.
- **Daily Challenges & Calendar Archive**: Play a curated puzzle every calendar day, browse past days in the archive, and earn milestone badges.
- **True Calendar-Day Streak Tracking**: Timezone-safe streak tracking that counts consecutive calendar days played (not number of games played on one day), complete with leap-year and boundary safety.
- **3D Clay Mascot & Avatars**: Warm visual style featuring 6 clay-sculpted dog breeds and reactive corgi mascot expressions (Happy, Excited, Thinking, Sleeping, Sad).
- **Comprehensive Statistics**: Track total games played, levels completed, win rate, best solve times, and day streaks in the dedicated Progress tab.
- **Settings & Accessibility**: Sound effects, haptic toggles, audio volume sliders, Light & Dark themes, tutorial replay, and data management.

---

## 🧠 Puzzle Intelligence System

SnapDog is powered by a multi-stage puzzle intelligence pipeline:

```
┌────────────────────────────────────────────────────────┐
│               PUZZLE INTELLIGENCE PIPELINE             │
├────────────────────────────────────────────────────────┤
│  1. PuzzleSolver (Uniqueness Oracle)                   │
│     • Validates exactly 1 unique solution              │
│     • Rejects ambiguous (multi-solution) or zero-sol   │
├────────────────────────────────────────────────────────┤
│  2. DeductionEngine & DifficultyClassifier             │
│     • Evaluates logical solvability                    │
│     • Classifies: Easy (Naked Singles),                │
│       Medium (Pointing Line/Region Reductions),        │
│       Hard (Mutual Adjacency & Look-Ahead Contradiction)│
├────────────────────────────────────────────────────────┤
│  3. ProgressiveHintService                             │
│     • Stage 1: Highlights constraint (Row/Col/Region)  │
│     • Stage 2: Explains eliminations & marks crosses   │
│     • Stage 3: Identifies forced dog cell & places dog │
├────────────────────────────────────────────────────────┤
│  4. PuzzleGenerator & DifficultyScheduler              │
│     • 4 Generation Strategies: Adaptive Cellular,      │
│       Directional Bands, Voronoi, Boundary Perturb     │
│     • Canonical PuzzleFingerprint duplicate rejection  │
│     • Mixed casual curve: ~50% Easy, ~35% Med, ~15% Hard│
│     • Strict rules: Max 1 consecutive Hard,            │
│       Max 3 consecutive Easy                           │
└────────────────────────────────────────────────────────┘
```

---

## 🐾 Dog Avatars & Breeds

The game includes custom 3D clay-rendered avatars for 6 dog breeds:

| Breed | Avatar Asset | Breed | Avatar Asset |
| :--- | :--- | :--- | :--- |
| **Beagle** | `assets/images/dogs/beagle.png` | **Husky** | `assets/images/dogs/husky.png` |
| **Corgi** | `assets/images/dogs/corgi.png` | **Labrador** | `assets/images/dogs/labrador.png` |
| **Golden Retriever** | `assets/images/dogs/golden_retriever.png` | **Pug** | `assets/images/dogs/pug.png` |

---

## 🏗️ Project Architecture

The codebase follows feature-driven layered architecture using **Riverpod** for state management:

```
lib/
├── core/
│   ├── constants/        # App colors, typography, assets
│   ├── theme/            # Light & Dark theme definitions
│   └── utils/            # Timezone-safe streak utilities, audio & haptics
├── features/
│   ├── game/             # Core gameplay screen, board widget, gestures
│   │   ├── models/       # Puzzle, DogPlacement, ProgressiveHint, DeductionStep
│   │   ├── providers/    # GameProvider (gameplay loop, timers, undo stack)
│   │   ├── services/     # PuzzleSolver, DeductionEngine, DifficultyClassifier,
│   │   │                 # PuzzleGenerator, DifficultyScheduler, PuzzleFingerprint
│   │   └── widgets/      # PuzzleBoardWidget, HintDialog, CompletionDialog
│   ├── daily_challenge/  # Daily puzzle mode, calendar screen, milestone rewards
│   ├── progression/      # Endless level tracking, persistence repository
│   ├── statistics/       # StatisticsScreen, GameStats model, StatsRepository
│   ├── settings/         # SettingsScreen, SettingsRepository, sound toggles
│   ├── home/             # HomeScreen, navigation shell, mascot card
│   ├── onboarding/       # Interactive tutorial dialog
│   └── splash/           # Animated splash screen with mascot
└── shared/
    └── widgets/          # DogAvatar, PawIcon, SnapDogButton, DogMascot
```

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`^3.13.7` or later)
- Dart SDK (`^3.13.7` or later)
- Android Studio / Xcode / VS Code with Flutter extension

### Installation

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/snapdog.git
   cd snapdog
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   ```bash
   flutter run
   ```

---

## 🧪 Running Tests & Quality Assurance

SnapDog maintains a suite of unit, widget, and integration tests covering the solver, deduction engine, hint pipeline, procedural generator, streak tracker, and gameplay UI.

### Run All Tests
```bash
flutter test
```

### Run Static Analysis
```bash
flutter analyze
```

### Build Android Debug APK
```bash
flutter build apk --debug
```

### Key Test Suites

- **Step 1 — Unique-Solution Solver**: `test/puzzle_solver_step1_test.dart`
- **Step 2 — Deduction Engine & Classifier**: `test/deduction_engine_step2_test.dart`
- **Step 3 — Progressive Hints**: `test/hint_system_step3_test.dart`
- **Step 4 — Procedural Generation & Scheduling**: `test/puzzle_generator_step4_test.dart`
- **Streak & Statistics System**: `test/streak_statistics_test.dart`
- **Daily Challenges**: `test/daily_challenge_test.dart`
- **Cell Gestures & Performance**: `test/cell_interaction_performance_test.dart`, `test/drag_to_cross_test.dart`

---

## 📄 License

This project is proprietary and confidential. All rights reserved.
