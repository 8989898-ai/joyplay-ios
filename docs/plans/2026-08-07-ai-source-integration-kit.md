# JoyPlay AI Source Integration Kit Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:test-driven-development to implement this plan task-by-task.

**Goal:** Package the existing non-SPM integration source and instructions so an AI can copy only the required code into a customer UIKit project and verify the result deterministically.

**Architecture:** Move the two canonical core files into a synchronized `JoyPlayIntegration` subdirectory so the Demo and the distributed source use the same files. Keep Demo controllers and resources outside that directory. Add project-specific AI rules and a structured request template that supply the product decisions an AI must not guess.

**Tech Stack:** Swift 5, UIKit, WebKit, YAML template, Markdown instructions, standalone Swift contract tests, Xcode simulator build.

---

### Task 1: Specify the distributable source layout

**Files:**
- Create: `Tests/AIIntegrationKitTests.swift`
- Modify: `Tests/IntegrationSurfaceTests.swift`
- Modify: `Tests/IntegrationGuideTests.swift`

1. Require the two core sources under `joyplay-ios/JoyPlayIntegration/` and require their old root paths to be absent.
2. Require `AGENTS.md` to distinguish core source from Demo-only controllers and define exact verification boundaries.
3. Require `INTEGRATION_REQUEST.yaml` to contain target project, scheme, mode hosts, credential sources, close behavior, and recharge behavior.
4. Run the tests and confirm they fail because the new layout and files do not exist.

### Task 2: Build the source integration kit

**Files:**
- Move: `joyplay-ios/GameConfiguration.swift` to `joyplay-ios/JoyPlayIntegration/GameConfiguration.swift`
- Move: `joyplay-ios/GameWebView.swift` to `joyplay-ios/JoyPlayIntegration/GameWebView.swift`
- Create: `AGENTS.md`
- Create: `INTEGRATION_REQUEST.yaml`

1. Move, rather than duplicate, the canonical source files so the Demo and delivered source cannot drift.
2. Add concise AI instructions with invariants, allowed scope, forbidden Demo copying, lifecycle rules, and completion reporting.
3. Add a placeholder-only YAML request that forces the integrating party to supply decisions the AI cannot safely infer.
4. Run the layout tests and confirm success.

### Task 3: Update the human guide and verify

**Files:**
- Modify: `README.md`
- Modify: `docs/plans/2026-08-07-integration-guide-and-events.md`

1. Update current integration paths and focused test commands.
2. Explain the AI workflow and the role of `INTEGRATION_REQUEST.yaml` without duplicating `AGENTS.md`.
3. Run all standalone focused tests with writable module-cache paths.
4. Run `git diff --check`.
5. Build the `joyplay-ios` scheme for a generic iOS Simulator with signing disabled and a fresh DerivedData path.
6. Inspect the task diff and confirm unrelated UI, credentials, URL, game ID, and layout behavior remain unchanged.
