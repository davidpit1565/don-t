# App Store Connect: copy-paste values

Everything below matches what the app actually does. Do not add claims (leaderboards, sync, social features) that do not exist.
Nothing here has been submitted; you do the submission yourself.

## 0. Before you start
- Paid **Apple Developer Program** membership; select your **Team** in Xcode → target DontPress → Signing & Capabilities.
- Bundle ID in the project: `com.davidpitchkhadze.dontpress` (cannot be changed after you create the app record).
- Business → accept the **Paid Apps Agreement** and fill banking + tax (needed for Pro).

## 1. Create the app (My Apps → +)
| Field | Value |
| --- | --- |
| Platform | iOS |
| Name | DON'T PRESS |
| Primary language | English (U.S.) |
| Bundle ID | com.davidpitchkhadze.dontpress |
| SKU | dontpress-001 (any unique string) |

## 2. App Information
| Field | Value |
| --- | --- |
| Subtitle (max 30) | Whatever you do. Don't. |
| Category | Entertainment (secondary: Games > Casual, optional) |
| Content rights | Does not contain third-party content |
| Privacy Policy URL | https://github.com/davidpit1565/don-t/blob/main/docs/privacy.md |

## 3. Version 1.0 page
| Field | Value |
| --- | --- |
| Promotional text (max 170) | One big red button. One simple rule. Good luck. |
| Keywords (max 100) | button,press,red button,funny,clicker,tap,satisfying,haptic,fidget,absurd |
| Support URL | https://github.com/davidpit1565/don-t/blob/main/docs/support.md |
| Marketing URL | (leave empty) |
| Copyright | © 2026 David Pitchkhadze |
| Screenshots | iPhone 6.9": upload the 8 files in `docs/appstore/` in numeric order |

**Description:**

```
You were told not to press it.

DON'T PRESS is a single, beautifully overbuilt red button. Every press feels great, adds to your current run, and earns a reaction you probably deserve. Beat your own personal best, keep an eye on your lifetime total, and share a clean achievement card when you've gone too far.

• Tactile button with real haptics
• 100+ hand-written reactions that escalate the longer you ignore the warnings
• 12 achievements and 5 button styles (Classic, Blue Mistake, Stealth, Radioactive, Gold Standard) that unlock as you go
• Optional one-time Pro purchase unlocks every button style instantly
• Current run, personal best and total presses
• Shareable achievement image through the standard iOS share sheet
• Works fully offline. No account, no ads, no tracking.
```

## 4. App Privacy ("Data Types")
Answer **Data Not Collected**. Justification (from the code): no analytics, ads or third-party SDKs; the only network use is Apple's StoreKit for the optional purchase, which Apple handles. Re-verify before publishing.

## 5. Age rating
Answer **No / None** to every content question (violence, sexual content, profanity, gambling, horror, etc.). Unrestricted web access: **No**. Expected rating: **4+**. Confirm the result in the questionnaire.

## 6. Pricing and availability
Free app. Choose territories. (The optional purchase is configured separately, below.)

## 7. In-App Purchase (Monetization → In-App Purchases → +)
| Field | Value |
| --- | --- |
| Type | Non-Consumable |
| Reference name | DON'T PRESS Pro |
| Product ID | `com.davidpitchkhadze.dontpress.pro` (exactly) |
| Price | Tier ≈ €1.99 |
| Display name | DON'T PRESS Pro |
| Description | Unlock all button styles right away. |
| Review screenshot | Take a real one in TestFlight (Collection → tap a locked style → the Pro offer showing the price). The simulator image in CI shows "unavailable", so do not use it. |
| Review notes | Tap the trophy, then a locked style, to see the offer. Restore Purchases is on the same screen. |

Attach the in-app purchase to version 1.0 under "In-App Purchases and Subscriptions" on the version page before you submit.

## 8. App Review Information
- Sign-in required: **No**.
- Contact: David Pitchkhadze, davidpit2008@gmail.com (add your phone number).
- Notes (paste):

```
DON'T PRESS is a fully offline, single-player toy. There is no login and no account, so no demo account is needed. The only network use is Apple's StoreKit for one optional in-app purchase ("DON'T PRESS Pro", non-consumable) that unlocks all button styles immediately; the same styles can also be earned for free by playing.

How to see everything in about a minute:
1. Tap the big red button. Each press increments Current Run and Total Presses, plays a light haptic and shows a different hand-written reaction (100+ lines in six tiers that escalate as the run grows).
2. Keep tapping: at 10, 25, 50, 100, 250, 500 and 1,000 presses a milestone line and a stronger haptic fire once. 12 achievements and 5 button styles unlock as thresholds are reached; a banner announces each unlock.
3. Tap the trophy icon (top right) to open Collection: choose an unlocked button style and see locked ones with their requirements and progress. Tapping a locked style, or the Pro row at the bottom, shows the optional Pro offer (price, what it includes, and Restore Purchases).
4. Tap "Share personal best" (enabled after the first press) to render a portrait achievement card with the user's real number and open the standard iOS share sheet.

Current Run starts at zero on every cold launch by design; Personal Best and Total Presses are stored locally. The app collects no data. Privacy Policy and Support links are at the bottom of the main screen.
```

## 9. Build upload (on your Mac)
1. Xcode → open `DontPress.xcodeproj` → scheme DontPress → destination **Any iOS Device (arm64)**.
2. Product → Archive → Distribute App → App Store Connect → Upload. (Export compliance is already declared: no non-exempt encryption.)
3. In App Store Connect → TestFlight: wait for processing, add yourself as an internal tester, install, and test:
   - the button, haptics, share sheet, the Collection, VoiceOver, large text
   - **a Sandbox purchase of Pro and Restore Purchases** (Settings → Developer → Sandbox account)
4. Version 1.0 → select the build → Add for Review → Submit (**only when you decide**).

## 10. Known risks (be realistic)
- 4.2 Minimum Functionality / 4.3 similar apps are the likeliest reasons for a rejection. The achievements, styles and notes above are the mitigation; approval is not guaranteed.
- If the in-app purchase is missing or not attached when the reviewer opens the Pro offer, the buy button is disabled and the build can be rejected (2.1). Attach it first.
