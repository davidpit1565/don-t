# DON'T PRESS: App Store readiness

Status of this document: **preparation only. Nothing has been submitted or published,
and approval is not promised.** Items are labelled Verified (checked in this repo),
or Open (needs the owner, a Mac, or Apple tooling).

## Project facts (verified from the files)

| Item | Value |
| --- | --- |
| Display name | DON'T PRESS (`INFOPLIST_KEY_CFBundleDisplayName`) |
| Bundle ID | `com.davidpitchkhadze.dontpress` (chosen for the owner; tests use `.tests` / `.uitests`). It cannot be changed after the App Store Connect record is created. |
| Version / build | 1.0 / 1 (`MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`) |
| Deployment target | iOS 17.0, iPhone only (`TARGETED_DEVICE_FAMILY = 1`), portrait, dark appearance forced |
| Signing | Automatic; `DEVELOPMENT_TEAM` is empty. **No team or credentials were invented.** |
| Encryption | `ITSAppUsesNonExemptEncryption = NO` (the app uses no networking or custom crypto) |
| Dependencies | None. No third-party packages, no SDKs. |
| Icon | `DontPress/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png`: single 1024 px RGB PNG, no alpha |
| Privacy manifest | `DontPress/PrivacyInfo.xcprivacy`: no tracking, no collected data, UserDefaults reason `CA92.1` |

## Blockers before submission (Open)

1. Select your **development team** in Xcode (Signing & Capabilities); confirm you are happy with the bundle ID before creating the App Store Connect record.
2. **Build, run, and test on a Mac.** No Xcode build has been performed on this project yet.
3. **Privacy policy and support pages** are written (`docs/privacy.md`, `docs/support.md`, contact: David Pitchkhadze,
   davidpit2008@gmail.com) and linked inside the app (`AppLinks.swift`). The links point to
   `https://github.com/davidpit1565/don-t/blob/main/docs/...`, which **only resolves after this branch is merged to `main`**
   (the repository must stay public). Use those same URLs in App Store Connect, or enable GitHub Pages and update `AppLinks.swift`
   and the metadata together. Confirm both pages open in a logged-out browser before submitting.
4. Confirm the app name is available in App Store Connect and does not collide with an existing product (4.1, 2.3.7; the limit is 30 characters, and "DON'T PRESS" is 11).
5. Capture real screenshots from a simulator or device (2.3.3).
6. Answer the age-rating questionnaire in App Store Connect (expected to be 4+; confirm there).
7. Decide on pricing and availability.

## Guideline review (checked against the live App Review Guidelines page)

* **4.2 Minimum Functionality.** This is the main risk. The app is deliberately tiny. What it has to
  stand on: a polished tactile interaction (custom press physics and haptics), 100+ hand-written reactions
  that escalate over a run, sessions with a personal best, milestone moments, and a rendered achievement image.
  A reviewer could still judge it "not particularly useful, unique, or app-like". Mitigations: keep the
  review notes concrete, show the escalation in screenshots, and consider extra original content before
  submitting (more reactions, a small set of unlockable button looks, and so on) if you want more margin.
* **4.3(b) Spam / indistinguishable from existing apps.** "Don't press the button" apps exist. Reactions, art,
  icon and code here are original, but expect to be compared with them. Do not reuse anyone's wording or art.
* **4.1 Copycats.** No third-party names, icons or Apple branding are used.
* **5.1.1 / 5.1.2 Privacy.** No accounts, analytics, ads, network access or permissions. Local counters only.
  A privacy policy is still required (see blockers).
* **2.3 Accurate metadata.** The text below describes only what the code does. Do not add claims such as
  "global leaderboard", "sync", or "Instagram/TikTok integration"; none exist.
* **1.5 Support URL.** Needs a real contact route.

## Suggested metadata (draft; edit freely)

* **Name:** DON'T PRESS
* **Subtitle (≤30):** Whatever you do. Don't.
* **Promotional text:** One big red button. One simple rule. Good luck.
* **Description:**
  > You were told not to press it.
  >
  > DON'T PRESS is a single, beautifully overbuilt red button. Every press feels great, adds to your current
  > run, and earns a reaction you probably deserve. Beat your own personal best, keep an eye on your lifetime
  > total, and share a clean achievement card when you've gone too far.
  >
  > • Tactile button with real haptics
  > • 100+ hand-written reactions that escalate the longer you ignore the warnings
  > • 12 achievements and 5 button styles (Classic, Blue Mistake, Stealth, Radioactive, Gold Standard) that unlock as you go
  > • Optional one-time Pro purchase unlocks every button style instantly (they can also be earned for free)
  > • Current run, personal best and total presses
  > • Shareable achievement image through the standard iOS share sheet
  > • Works fully offline. No account, no ads, no tracking.
* **Keyword ideas (≤100 chars, check them yourself):** `button,press,red button,funny,clicker,tap,satisfying,haptic,fidget,absurd`
* **Category:** Entertainment (primary; matches `LSApplicationCategoryType`). Consider Games > Casual as an alternative.

## Screenshots (generated; in `docs/appstore/`)

Eight 1320×2868 PNGs (iPhone 6.9"), built by `Scripts/make_store_screenshots.py` from **unedited iOS Simulator
captures taken by the CI UI tests** (`ScreenshotTests`) and the app's own rendered share card. Nothing on screen is
mocked up. Order: 1 hook, 2 reactions, 3 unlocks/milestones, 4 escalation, 5 collection, 6 button style, 7 share card, 8 private/offline.
Upload them to the 6.9" slot in App Store Connect; Apple scales them for smaller iPhones. The headlines are marketing
copy and the screens are real. Re-run the CI workflow and the script after any UI change so they stay accurate (2.3.3).
No iPad screenshots are needed (iPhone-only).

## Privacy declaration (derived from the code)

* Data collected: **None.** Nothing leaves the device. The app contains no networking code, SDKs or analytics.
* Stored locally: personal best and total press count (`UserDefaults`, keys `dontpress.personalBest`, `dontpress.totalPresses`). The current run is never stored.
* Tracking: **No.** Required-reason API: UserDefaults (`CA92.1`).
* App Store Connect "App Privacy" answer expected: *Data Not Collected*. **Not finalised.** Re-verify against the shipped build and confirm in App Store Connect.

## Privacy policy checklist

- [ ] States that no personal data is collected or transmitted
- [ ] States that the two counters are stored on the device only and are removed when the app is deleted
- [ ] Mentions the share sheet: the image goes only where the user sends it
- [x] Contact route for questions (written in `docs/privacy.md`)
- [ ] Hosted at a stable public URL (after merge to `main`); linked in App Store Connect **and** inside the app (in-app link is implemented, unverified)

## Support page checklist

- [x] Contact email (written in `docs/support.md`)
- [x] Short FAQ (written)
- [ ] Hosted at a stable public URL (after merge to `main`)

## Verification checklist before upload

- [ ] `xcodebuild test` passes on a simulator (see README)
- [ ] Manual pass: VoiceOver, Dynamic Type (including the AX sizes), Reduce Motion, small iPhone (SE) and large iPhone
- [ ] Real-device haptics check
- [ ] Share to Photos/Messages; cancel from the share sheet; confirm stats unchanged
- [ ] Archive, validate, and upload through Xcode Organizer (**only with the owner's explicit go-ahead**)


## App Review Notes (paste into App Store Connect → App Review Information → Notes)

> DON'T PRESS is a fully offline, single-player toy. There is no login and no account, so no demo account is needed. The only network use is Apple's StoreKit for one optional in-app purchase ("DON'T PRESS Pro", non-consumable) that unlocks all button styles immediately; the same styles can also be earned for free by playing.
>
> How to see everything in about a minute:
> 1. Tap the big red button. Each press increments Current Run and Total Presses, plays a light haptic and shows a different hand-written reaction (100+ lines in six tiers that escalate as the run grows).
> 2. Keep tapping: at 10, 25, 50, 100, 250, 500 and 1,000 presses a milestone line and a stronger haptic fire once. Achievements (12) and button styles (5) unlock as thresholds are reached; a banner announces each unlock.
> 3. Tap the trophy icon (top right) to open Collection: choose an unlocked button style and see locked ones with their requirements and progress. Tapping a locked style, or the Pro row at the bottom, shows the optional Pro offer (price, what it includes, and Restore Purchases). To test the purchase, use a Sandbox Apple ID.
> 4. Tap "Share personal best" (enabled after the first press) to render a portrait achievement card with the user's real number and open the standard iOS share sheet.
>
> Current Run starts at zero on every cold launch by design; Personal Best and Total Presses are stored locally (UserDefaults). The app collects no data. Privacy Policy and Support pages are linked at the bottom of the main screen.

**Reviewer-friendly framing (keep it accurate):** do not claim leaderboards, sync, or social features; none exist.
