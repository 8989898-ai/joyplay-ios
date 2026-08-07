# Partial-Screen Back Navigation Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Make the top back button in half and large-half modes return to the three-Tab screen with the full-screen Tab selected, whether or not an embedded game is visible.

**Architecture:** Keep `GameModeTabBarController` responsible for both Tab Bar visibility and its navigation item. Add a small testable return-destination rule to `GameDisplayMode`, then use it to install a custom back button only for the two embedded modes.

**Tech Stack:** Swift, UIKit, WebKit, Auto Layout, command-line Swift tests, Xcode.

---

### Task 1: Specify the back destination

**Files:**
- Modify: `Tests/main.swift`
- Modify: `joyplay-ios/GameConfiguration.swift`

1. Add assertions that full screen returns to the previous screen while half and large-half return to the full-screen Tab.
2. Run the focused Swift test and confirm it fails because the full-screen Tab destination is missing.
3. Update `GameBackDestination` and the minimal `GameDisplayMode.backDestination` mapping.
4. Run the focused test and confirm it passes.

### Task 2: Route the partial-screen back button

**Files:**
- Modify: `joyplay-ios/GameModeTabBarController.swift`

1. Centralize selected-mode lookup and navigation-item updates in the Tab controller.
2. Install a custom back button whenever half or large-half is selected; remove it for full screen.
3. On custom back, ask the selected launch controller to remove an embedded game if present, select the full-screen Tab, then show the mode Tab Bar.
4. Keep the H5 close callback and full-screen push path unchanged.

### Task 3: Verify

**Files:**
- Verify: `Tests/main.swift`
- Verify: `joyplay-ios/GameConfiguration.swift`
- Verify: `joyplay-ios/GameModeTabBarController.swift`

1. Run the focused Swift tests and expect `GameConfiguration tests passed`.
2. Run `git diff --check` on the task files.
3. Run an unsigned simulator build and expect `BUILD SUCCEEDED`.
4. Inspect the final diff to confirm no login, Token, URL, full-screen, or H5 callback behavior changed.
