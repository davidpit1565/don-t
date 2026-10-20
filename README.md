# DON'T PRESS

*Whatever you do, don't press it.*

A native SwiftUI iPhone app: one large, tactile red button that tells you not to press it. Every press
counts, buzzes, and earns a hand-written reaction. Fully local and offline, with no accounts, backend, ads or analytics.

- **Spec:** [`CLAUDE.md`](./CLAUDE.md)
- **Release notes and App Store checklist:** [`docs/RELEASE.md`](./docs/RELEASE.md)
- **Privacy policy:** [`docs/privacy.md`](./docs/privacy.md) · **Support:** [`docs/support.md`](./docs/support.md)

## Features

- Custom `ButtonStyle` with press-down depth, spring release, and native haptics (light impact; stronger on milestones). Reduce Motion simplifies the animation.
- 100+ curated reactions in six press-count tiers, plus milestone lines (10, 25, 50, 100, 250, 500, 1000). No immediate repeats.
- **Current run** (this app session), **personal best** and **total presses** (persisted in `UserDefaults`).
- Share a rendered 1080×1350 achievement card (SwiftUI `ImageRenderer`) through the system share sheet.
- **Collection:** 12 local achievements and 5 button styles (Classic + 4 unlockable) derived from the saved stats; unlock banner.
- Accessibility labels/values/hints, Dynamic Type (stats stack at accessibility sizes), dark-mode-first UI.

### Session semantics

A cold launch always starts the current run at 0. Backgrounding, returning, and opening or cancelling the
share sheet do not reset it (one view model lives for the process). Personal best updates the moment the
run exceeds it. Stored values that are missing, negative, or the wrong type read as 0. Counters saturate at
`Int.max` and never go negative. There is no reset button.

## Layout

```
DontPress/            app target (Xcode folder-synchronized group)
  App/ Core/ Design/ Views/ Share/ Haptics/ Assets.xcassets PrivacyInfo.xcprivacy
DontPressTests/       XCTest unit tests (Core logic)
DontPressUITests/     XCUITest flows
Package.swift         dev convenience: runs the Core + unit tests with `swift test` (also on Linux)
Scripts/generate_xcodeproj.py   regenerates DontPress.xcodeproj
docs/RELEASE.md
```

`DontPress/Core` is Foundation/Observation-only (no UIKit/SwiftUI), so it is testable anywhere.

## Run it (requires macOS + Xcode 16+)

```sh
open DontPress.xcodeproj          # select scheme "DontPress", run on an iPhone simulator
# set your Team and bundle identifier first: Signing & Capabilities (currently the placeholder com.example.dontpress)

xcodebuild test -project DontPress.xcodeproj -scheme DontPress \
  -destination 'platform=iOS Simulator,name=iPhone 16'

swift test        # Core unit tests only, no Xcode needed
```

UI tests launch the app with `-UITestMode` (isolated `UserDefaults` suite), optionally `-UITestReset`,
`-UITestSeedBest N`, `-UITestSeedTotal N`.

## Verification status

See the "Status" section of the final report in the session that produced this change; summarised here:

| Area | Status |
| --- | --- |
| Core logic (counting, persistence, reactions, share content, view model) | Built and automated-tested with `swift test` on Linux (Swift 6.0.3): 44 tests |
| SwiftUI/UIKit views, haptics, share rendering, Xcode project, UI tests | Implemented, **not built, not run, not simulator-verified** (no macOS/Xcode in the authoring environment) |
| App icon | Implemented (1024 px PNG viewed as an image); not checked in Xcode or on a device |
