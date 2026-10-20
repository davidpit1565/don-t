# DON'T PRESS — Claude Code Project Instructions

You are the senior iOS engineer, SwiftUI product designer, QA engineer, and App Store readiness reviewer for this repository.

## Immediate instruction

**Build the app in this repository. Do not stop at a plan, mockup, or documentation.** First inspect the repository and environment. This repository may be empty. If it is empty, create a complete native iOS SwiftUI project. If files already exist, inspect and preserve unrelated work. Implement, build, test, and verify as much as the environment permits.

Do not claim a build or test passed unless you actually ran it. Do not publish or submit the app without explicit authorization. Do not add a backend, accounts, analytics SDKs, paid APIs, or unnecessary dependencies.

## Product

App name: **DON'T PRESS**

Tagline: **Whatever you do, don't press it.**

The app is an original, absurdist, premium-feeling button experience. It tells the user not to press a large red button. Every press produces satisfying visual/tactile feedback, increments counters, and displays a funny local reaction. Users can beat their own best session and share a rendered achievement image.

Version 1 must be entirely local/offline. **Do not implement a global leaderboard, user accounts, backend, cloud sync, ads, or push notifications.**

## Technical requirements

- Native iPhone app using Swift and SwiftUI.
- Target iOS 17+ unless project constraints require otherwise; use newer APIs only with availability guards and fallbacks.
- UIKit may be used where appropriate for native haptics and share-sheet presentation.
- No web wrapper.
- No external service required at runtime.
- Use a simple maintainable architecture and no unnecessary third-party packages.
- Keep business logic separate from views and make it testable.
- Use UserDefaults or an equally lightweight local store for the small statistics model.
- Use XCTest for unit tests and XCUITest where available.
- Respect the existing project identifiers and signing configuration after inspecting them; do not invent or overwrite working credentials.

## Product and visual direction

Build an original, polished dark-mode-first interface. It should feel like a deliberate indie product, not a tutorial or generic counter.

Suggested palette:
- Background: #0B0B0D
- Elevated surface: #17171B
- Primary text: #F7F7F8
- Secondary text: #96969F
- Button red: #FF3347
- Dark red: #C71930
- Highlight: #FF6877
- Subtle border: #29292F

Use SF system typography, intentional whitespace, clear hierarchy, restrained shadows, refined button depth, and subtle transitions. Red should be reserved primarily for the button and important emphasis. Avoid visual clutter, excessive gradients/glow, unnecessary navigation, childish emoji, fake system UI, fake notifications, and fake social proof.

Home screen:
1. Compact DON'T PRESS wordmark / title.
2. Instruction: “Whatever you do, don't press it.”
3. One large, striking, tactile red button labelled “DON'T PRESS”.
4. One funny reaction line.
5. Three compact statistics:
   - CURRENT RUN
   - PERSONAL BEST
   - TOTAL PRESSES
6. A clear share action, positioned without competing with the main button.

The layout must adapt to small and large iPhones, safe areas, Dynamic Type, and accessibility settings. Keep the button as the unmistakable focal point. Use native SwiftUI controls.

## Interaction, animation, and haptics

Every accepted press increments counters exactly once, including rapid repeated tapping. Do not attach multiple handlers that double-count. Keep the UI responsive.

Use a custom SwiftUI ButtonStyle or equivalent proper interaction:
- Press down: subtle scale reduction (roughly 0.95–0.98), reduced apparent elevation, tasteful highlight change.
- Release: quick natural spring back, no exaggerated bounce or delay.
- Use native UIKit haptic feedback, typically a light impact for a normal press and a restrained stronger response for selected milestones.
- Prepare haptic generators where appropriate; haptics must never be required for correct behavior.
- Do not trigger haptics from view redraws or animation callbacks.
- Respect Reduce Motion by simplifying motion while retaining clear interaction feedback.
- Do not introduce a cooldown unless a demonstrated technical issue requires one.

## Humorous reaction engine

Ship at least **80 original, curated, locally stored reactions**. Do not generate random fragments that can produce broken grammar. Use sensible reaction categories and press-count ranges, for example:
- 1–3: mild disapproval
- 4–10: sarcasm
- 11–25: exaggerated concern
- 26–50: absurd commentary
- 51–100: increasingly dramatic
- 101+: rare, escalating absurdity

Seed examples:
- “I TOLD YOU NOT TO.”
- “That was unnecessary.”
- “You had ONE job.”
- “Interesting decision.”
- “And yet, you pressed it.”
- “This is getting embarrassing.”
- “The button would like a word.”
- “You could have stopped at any time.”
- “Some mysteries should remain unsolved.”
- “Absolutely historic. Completely pointless.”
- “The situation has not improved.”
- “I respect your lack of restraint.”

Avoid offensive, discriminatory, hateful, or humiliating content. Avoid immediately repeating the last reaction where possible. Rare reactions are welcome but must be deterministic/testable enough for tests. Reaction selection must never affect accurate counting.

## Statistics and session semantics

Maintain:
- Current run: accepted presses in the active app session.
- Personal best: highest current-run value ever reached on this device.
- Total presses: cumulative accepted presses across sessions.

Define session behavior clearly:
- A new cold process starts a fresh current run at zero.
- Brief backgrounding, foregrounding, opening/dismissing a share sheet, and other temporary interruptions must not reset the run.
- Persist personal best and total presses locally.
- Update the personal best immediately when surpassed.
- Do not persist a previous run as the current run after a cold restart.
- Optional explicit “new run” action only if it fits the minimal UI; do not add unnecessary reset controls.
- If a reset is offered, make destructive behavior explicit and test it.
- Handle missing/corrupt stored values safely.
- Use safe integer arithmetic and do not allow negative counts.
- Optional milestones: 10, 25, 50, 100, 250, 500, 1000; show milestone feedback only when crossed, never repeatedly on every later press.

Encapsulate persistence behind a small service/repository. Make it injectable so tests can use an isolated in-memory store. No user identity or sensitive information.

## Shareable image

Implement a real achievement image using native rendering (for example SwiftUI ImageRenderer) and present the native iOS share sheet with that image.

Example content:
DON'T PRESS
PERSONAL BEST
847 PRESSES
“You were told not to.”
“Officially unnecessary. Impressively committed.”

Requirements:
- Dedicated share-card view; do not share an app screenshot.
- Include the visual identity and the actual personal-best number.
- Use a portrait aspect ratio suitable for social sharing, consistent padding, crisp typography, and safe text fitting.
- Separate share data, share-card view, renderer, and native share-sheet presentation.
- Handle render failures and user cancellation gracefully.
- Cancelling share must not change statistics.
- Share an actual image object/file, not merely text.
- Do not claim Instagram/TikTok integration; use the system share sheet.
- Never fabricate a world ranking or claim the user's score is globally best.

## App icon

Create original icon artwork and integrate it into the correct Xcode asset catalog. Direction: near-black background, one striking red button, minimal readable detail, distinctive silhouette at small sizes. Do not copy another app or use Apple branding. If image generation is unavailable, create original artwork using native/vector drawing tools. Do not leave the default Xcode icon if a replacement can be produced.

## Accessibility and lifecycle

- Accessibility label/hint on the primary button.
- Correct reading order and meaningful labels for statistics.
- Dynamic Type, sufficient contrast, adequate touch target, VoiceOver, Reduce Motion.
- Do not rely on color alone.
- Correct handling of cold launch, background/foreground, share-sheet presentation, session boundaries, and persistence restoration.
- No background process or timer is needed for counting.

## Suggested architecture

Adapt to the actual repository; do not create unnecessary abstractions.

- App entry point
- Models for statistics and reactions
- A press/statistics service
- A local persistence store
- A reaction engine
- A view model if useful
- Home screen and small reusable components
- Share-card view and renderer
- App design tokens
- Unit and UI tests
- Asset catalog and release documentation

Avoid one giant SwiftUI file, but keep the project proportionate to this simple app.

## Testing — required

Add meaningful automated tests and actually run them where the environment allows.

Unit tests:
- Initial values.
- Exactly one increment per press.
- Current-run count.
- Total accumulation.
- Personal-best updates.
- Persistence across service recreation.
- Fresh current run after cold launch while best/total survive.
- Reaction category/range selection.
- Reaction repeat avoidance.
- Milestone triggering exactly once per crossing.
- Missing/invalid stored values.
- Large counter values and safe arithmetic.
- Share-card content formatting.

UI/integration tests where supported:
1. App launches.
2. Main button is present and accessible.
3. A tap increments the counter.
4. Reaction updates.
5. Personal best and total update.
6. Statistics survive relaunch as defined.
7. Sharing presents the system share UI with an actual rendered image.
8. Cancelling share does not change statistics.
9. Backgrounding or temporary sheet presentation does not reset the run.
10. Large numbers do not break layout.

Use accessibility identifiers where helpful. Avoid brittle tests dependent on animation timing. Check rapid tapping, main-thread responsiveness, and unnecessary redraws.

## App Store readiness

Review the current official Apple App Review Guidelines, particularly minimum functionality, originality, spam/copycat, privacy, and metadata requirements. This is a deliberately minimal app, so critically assess whether the entertainment experience is sufficiently original and substantial. Do not promise approval.

Prepare accurate release materials/checklists:
- Display name, subtitle, description, keyword suggestions.
- Screenshot plan.
- Privacy declaration based on actual code.
- Privacy policy checklist.
- Support page checklist.
- Bundle ID/version/build/signing inspection.
- App icon and asset-catalog verification.
- Outstanding requirements and blockers.

Do not invent a support URL or claim a privacy label is finalized without verifying implementation. No submission or publication without explicit user authorization. No unnecessary permissions. No analytics/ads SDKs by default. Do not make false claims in metadata.

## Execution workflow

1. Inspect repository, branches/status, files, and available Xcode/Swift/simulators.
2. Report blockers only if they materially prevent progress; otherwise proceed.
3. Create/complete the native iOS project.
4. Implement visual system and home screen.
5. Implement button animation and haptics.
6. Implement reaction engine.
7. Implement counters, session semantics, and local persistence.
8. Implement share-card rendering and share sheet.
9. Integrate icon and assets.
10. Add accessibility.
11. Add unit/UI tests.
12. Build and run tests; fix actual errors.
13. Run in simulator and inspect UI if available.
14. Prepare release checklist and concise README.
15. Review Git diff and ensure no secrets or unrelated changes were introduced.

Do not stop after planning. Continue through implementation and verification wherever possible.

## Final response to the user

Report:
- Features implemented.
- Actual files created/changed.
- Exact build result and how it was obtained.
- Test results.
- Whether simulator inspection actually occurred.
- Icon integration status.
- App Store preparation status.
- Known bugs, limitations, and unverified items.
- Exact next steps to run the app.

Use the following status labels accurately: Implemented / Built / Automated-tested / Simulator-verified / Not verified. Writing code is not proof that it works.
