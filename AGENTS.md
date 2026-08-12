English | [简体中文](AGENTS.zh-CN.md)

# JoyPlay iOS AI Integration Rules

AGENTS.md is authoritative. `AGENTS.zh-CN.md` is a convenience translation for Chinese-speaking maintainers.

This file applies both to maintaining the current Demo and to integrating JoyPlay games into another Swift and UIKit project. Explicit user requirements always take precedence.

## Required Reading Before Integration

1. Read the root `README.md` to confirm game modes, events, recharge handling, and cleanup rules.
2. Check the target project and its parent directories for additional `AGENTS.md` files and follow those project rules as well.
3. AI should automatically scan the target project to locate its project container, Scheme, App Target, candidate host controllers, complete backend game URL, aspect-ratio source, close paths, and recharge handling.
4. `INTEGRATION_REQUEST.yaml` is an optional set of business overrides and an integration record. A `null` value is unspecified and delegates to automatic discovery; an existing non-null value takes precedence over discovery.
5. If a business decision cannot be uniquely determined, such as when several host controllers, close behaviors, or recharge entry points are reasonable, stop changes to the affected location and ask only about the ambiguous item. Do not ask users to provide information that AI can determine from the project.
6. After scanning or clarification, AI may record the final choices in `INTEGRATION_REQUEST.yaml` for later review.
7. `docs/plans/` contains internal historical implementation records and is excluded from the delivered repository. Even if obtained elsewhere, do not treat it as the current contract. The current contract is defined by `README.md`, this file, and the core source.

## Distributable Core Source

When integrating into a target project, copy only the complete `joyplay-ios/JoyPlayIntegration/` directory and confirm that both Swift files belong to the target App Target:

- `GameConfiguration.swift`
- `GameWebView.swift`

The host initializes `GameWebView` directly with the complete backend URL, display mode, original embedded-mode `widthHeightRatio`, and event callback, then calls `attach(to:)` to add it to the business container. `GameWebView` owns the outer layout for every mode and is the only recommended host entry point. Do not make integrators duplicate game-view constraints or introduce a Session, Coordinator, or wrapper controller for an ordinary integration.

Unless the user explicitly asks to reproduce the Demo UI, do not copy:

- `DemoGameConfiguration.swift`
- `DemoRechargePromptPresenter.swift`
- `DemoGameLaunchButton.swift`
- `GameModeSelectionViewController.swift`
- `PartialGameViewController.swift`
- `FullScreenGameViewController.swift`
- `Localizable.xcstrings`
- The button colors and scene backgrounds in `Assets.xcassets`

## Local UI Copy and Localization

- All user-visible and accessibility copy in the current Demo must support English `en` and Simplified Chinese `zh-Hans`.
- Use native iOS localization and `String(localized:defaultValue:)`, follow the system language, and use English as the source language and default fallback.
- When adding or changing local copy, update both English and Simplified Chinese in `Localizable.xcstrings` and update the localization tests.
- Console logs, URLs, query parameters, asset names, AppKey, Token, JavaScript, and H5 callback names are not local UI copy and must not be localized.
- The core source does not present recharge UI. Demo recharge copy belongs only to `DemoRechargePromptPresenter.swift`.
- Do not copy the Demo `Localizable.xcstrings` when integrating another business project. The target app owns its recharge copy and string resources.
- Validate the string catalog with `xcrun xcstringstool compile` and use an unsigned simulator build to confirm that both language resources are bundled. A build does not replace visual runtime verification after changing the system language.

## Integration Contracts That Must Not Be Changed Without Approval

- The host backend supplies a complete HTTPS game URL, which the core `GameWebView` receives directly as `URL`.
- The backend URL contains `gameId=1`.
- The backend provides `mini=0`, `mini=1`, and `mini=2` for full screen, half screen, and large half screen respectively.
- The backend URL must not contain `safeTop` or `paddingBottom`. On its first full-screen load, the core appends `safeTop=1` and the current window bottom safe-area inset. Half screen and large half screen do not modify the URL.
- The half-screen and large-half-screen `widthHeightRatio` is width divided by height and comes from host backend configuration. The host passes the original value directly to `GameWebView`; the core validates it, converts it to a height multiplier, and aligns the bottom with the safe area. Do not make the host construct a core ratio type or hard-code a ratio in `GameDisplayMode` or the core source.
- `GameWebView` has a failable initializer. It returns `nil` for non-HTTPS URLs, missing hosts, URLs already containing `safeTop` or `paddingBottom`, embedded modes with a missing or invalid ratio, or full screen with a ratio. The host still owns the failure message and retry behavior.
- H5 message names are fixed as `recharge`, `clickRecharge`, `newTppClose`, and `OpenGameSucc`.
- The core does not know AppKey, Token, `gameId`, `mini`, or `isNativeDemo`. The current Demo uses in-source mock JSON containing three complete URLs decoded by `JSONDecoder`. Each Demo URL contains the matching `mini` and `isNativeDemo=1`; the business backend omits that marker by default.
- After `newTppClose`, the host removes the game view or pops according to its selected template. Do not close a live room, voice-chat room, or other business controller without explicit direction.
- Call `stop()` when the host actively exits.
- The host presents recharge UI after a recharge event and calls `notifyGameBalanceDidChange()` after a successful recharge.
- The Demo AppKey and Token may be public. Do not remove them merely because they appear in source or logs.

## AI Integration Procedure

1. Automatically scan and confirm the target project, Scheme, App Target, host controller, complete backend game URL, and aspect-ratio source. Apply any non-null override from `INTEGRATION_REQUEST.yaml`.
2. Copy the `JoyPlayIntegration` directory and keep its two files in the same target.
3. Pass the complete backend game URL, mode, and original embedded-mode ratio directly to `GameWebView`. After successful initialization, call `attach(to:)` to add it to the business container. On `nil`, follow the project's uniquely established behavior; ask the user if it cannot be uniquely determined. Do not repeat core validation or layout in the host or add Demo controllers or background assets.
4. Implement every `GameEvent` branch, even if a branch currently only logs.
5. Implement close and recharge behavior using the project's single unambiguous behavior or a non-null template override. Ask before changing an ambiguous business location.
6. Check that every active-removal path calls `stop()`.
7. Modify only the target files required for the integration. Do not refactor adjacent business code.

## Verification Requirements

First run `xcodebuild -list` to confirm the target container and Scheme. Then run an unsigned simulator build using the selected Scheme. For example:

```sh
xcodebuild -project <target-project.xcodeproj> \
  -scheme <target-scheme> \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath /tmp/joyplay-customer-derived-data \
  build CODE_SIGNING_ALLOWED=NO
```

For a Workspace, replace `-project` with `-workspace`. A successful build proves only static integration. It does not replace real H5 verification of game rendering, all four callbacks, close behavior, and balance refresh after recharge.

## Completion Report

After integration, AI must report:

- Files copied or modified.
- The host controller used for each enabled mode.
- Whether the game URL, aspect ratio, invalid URL or ratio handling, close behavior, and recharge behavior came from automatic discovery, a template override, or user confirmation.
- Tests and `xcodebuild` commands run, with their results.
- Real H5 or visual verification that still requires manual completion.
