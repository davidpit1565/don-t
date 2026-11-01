# Version 1.1: App Store Connect copy and release plan

Status: **draft, nothing submitted.** Version 1.0 is in App Review. 1.1 features (sounds, "the button fights back"
set-pieces, egg and balloon toys, daily challenge with day streak, better share card, Reactiondex) are being built on
separate branches. **Before pasting any of this, check every line against the 1.1 build you actually submit** and delete
anything that did not ship (guideline 2.3.1: metadata must match the app). Lines marked `[OWNER: ...]` need facts only the
final build can provide.

Related: [`privacy.md`](./privacy.md), [`support.md`](./support.md), [`PRO_2_0.md`](./PRO_2_0.md),
[`NAME_OPTIONS.md`](./NAME_OPTIONS.md), [`LAUNCH_PLAYBOOK.md`](./LAUNCH_PLAYBOOK.md), 1.0 values in
[`APP_STORE_CONNECT.md`](./APP_STORE_CONNECT.md).

## How the character limits were checked

Every block below tagged `<!-- count:name:limit -->` was counted with a script (Python `len()`, i.e. Unicode characters,
which is how App Store Connect counts) on the exact text in this file. Results at the time of writing:

| Field | Limit | Count |
| --- | --- | --- |
| Subtitle | 30 | 29 |
| Keywords | 100 | 100 (15 terms, no duplicates, no spaces) |
| Promotional text | 170 | 156 |
| What's New | 4000 | 632 (including the `[OWNER]` line; shorter once it is replaced or removed) |
| Description | 4000 | 1661 |
| App Review notes | kept well under 4000 | 1873 (before `[OWNER]` placeholders are filled) |

The keyword field is exactly at the limit: adding any term means removing one.

If you edit any block, recount (`python3 -c "print(len(open('x.txt').read().strip()))"` or paste into App Store Connect, which shows the remaining characters).

## 1. Subtitle (keyword-led)

<!-- count:subtitle:30 -->
```
Red Button Clicker Fidget Toy
```

Why: "red button", "clicker" and "fidget toy" are the plain words people type for this kind of app; the current
subtitle ("Whatever you do. Don't.") is on-brand but contains no search terms. Apple indexes the name, subtitle and
keywords together, so none of these words are repeated in the keyword field. Alternatives (also 30 or fewer):
`Red Button Prank & Fidget Toy` (29; "prank" may set the wrong expectation), `Don't Press the Big Red Button` (30; only
if the store name changes, see NAME_OPTIONS.md).

## 2. Keywords

<!-- count:keywords:100 -->
```
tap,satisfying,haptic,daily,streak,challenge,egg,hatch,balloon,pop,funny,boredom,stress,absurd,sound
```

Rules applied: comma separated with no spaces; no plurals of words already present; none of the name words ("don't",
"press"), the category ("entertainment") or the subtitle words ("red", "button", "clicker", "fidget", "toy").
If the store name changes (NAME_OPTIONS.md), redo this list so it does not repeat the new name's words.
Do not add competitor or trademarked names (guideline 2.3.7). "stress" describes how people use fidget apps; do not
make any health or anxiety-relief claim in the description.

## 3. Promotional text

Editable any time without a new build.

<!-- count:promo:170 -->
```
New in 1.1: the button fights back. Hatch creatures from an egg, pop a balloon, keep a daily streak and collect every reaction. Still offline, still no ads.
```

## 4. What's New in This Version

<!-- count:whatsnew:4000 -->
```
The button has had enough.

• The button fights back: at certain milestones it stops being polite. Short set-pieces you have to see for yourself.
• New toys: an egg that hatches creatures, and a balloon that pops. Same rule applies.
• Daily challenge: one new challenge every day, with a day streak to protect. Made on your iPhone, works offline.
• Reactiondex: collect every reaction and creature you discover.
• Sound: new synthesized sounds, with an on/off switch.
• A better share card for your personal best.
• Pro now includes the Egg and the Balloon toys and four alternate app icons, plus all button styles right away

Still no account, no ads, no tracking.
```

## 5. Description

<!-- count:description:4000 -->
```
You were told not to press it.

DON'T PRESS is a big, tactile red button with one rule. Every press feels great, adds to your current run, and earns a hand-written reaction you probably deserve. Ignore the warnings long enough and things escalate: the reactions get more dramatic, milestones fire, and eventually the button fights back.

WHAT YOU CAN DO
• Press the button. Real haptics, a satisfying press, and synthesized sounds (switch them off any time).
• Watch it escalate: 100+ hand-written reactions in tiers that change the longer your run goes.
• Survive the milestones: at certain press counts the button stops being polite and stages a short set-piece.
• Try the other toys: an egg that hatches creatures, and a balloon that pops. Same rule. Same bad decisions.
• Play the daily challenge: one new challenge every day, plus a day streak to protect.
• Fill your Reactiondex: every reaction and creature you discover is collected.
• Unlock 12 achievements and 5 button styles (Classic, Blue Mistake, Stealth, Radioactive, Gold Standard) by playing.
• Beat yourself: current run, personal best and total presses.
• Share a clean achievement card with your real personal best through the standard iOS share sheet.

OPTIONAL PRO
One optional one-time purchase, no subscription: the Egg and the Balloon toys, four alternate app icons, and every button style right away. The app shows exactly what Pro includes, and the price, before you buy. The big button, the milestone moments, the daily challenge, the streak, the Reactiondex, the share card and every style you earn by playing stay free.

PRIVATE BY DESIGN
Works fully offline. No account, no ads, no tracking, no analytics. Your progress stays on your iPhone. There are no global rankings: the only person you are competing with is you.
```

Check before pasting: the counts (12 achievements, 5 styles, 100+ reactions) are true for 1.0 today; update them if 1.1
adds styles, achievements or reactions. If Pro 2.0 (PRO_2_0.md) is adopted, the "OPTIONAL PRO" paragraph stays accurate
as written; if any toy ends up Pro-only, remove it from the "stay free" sentence.

## 6. App Review notes (version 1.1)

Purpose: lead with the concrete mechanics so a reviewer sees an app with several distinct, original interactions
(guideline 4.2 minimum functionality) that is not a re-skin of other "button" apps (4.3 spam). Fill in the
`[OWNER: ...]` parts from the real build; vague notes are worse than none.

<!-- count:review_notes:4000 -->
```
DON'T PRESS is a fully offline, single-player toy with several distinct mechanics, not a single counter. No login or account, so no demo account is needed.

What to try (about 3 minutes):
1. Button and reactions: tap the big red button. Each press increments Current Run and Total Presses, plays a haptic and a synthesized sound (sound toggle in the app), and shows a hand-written reaction. 100+ original lines in tiers escalate as the run grows; the same line is never shown twice in a row.
2. The button fights back: keep tapping. At milestone counts the button performs a short animated set-piece, once per crossing. [OWNER: exact milestones and what happens at the first one, e.g. "at 10 presses the button ..."]
3. Toys: switch from the button to the egg (pressing it eventually hatches a creature) or the balloon (it inflates and pops). [OWNER: name the control and the press counts.]
4. Daily challenge: open the daily challenge and finish today's challenge; the day streak starts at 1. It is generated on the device from the date; there is no server.
5. Reactiondex: discovered reactions and creatures are collected here; undiscovered entries stay hidden until found.
6. Collection: tap the trophy icon for 12 achievements and 5 button styles that unlock by playing.
7. Share: tap "Share personal best" to render an achievement image with the real number and open the iOS share sheet.

In-app purchase: one non-consumable, com.davidpitchkhadze.dontpress.pro. Pro includes the Egg and the Balloon toys, four alternate app icons and all button styles; the offer opens when you tap a locked toy (Egg/Balloon in the bottom picker), a locked style or icon in Collection (trophy), or the Pro row. Restore Purchases is on the same screen. Please use a Sandbox Apple ID to test.

Current Run starts at zero on every cold launch by design. All progress is stored on the device (UserDefaults). The app collects no data, requests no permissions and sends no notifications. Privacy Policy and Support are linked at the bottom of the main screen.
```

Also: if the reviewer needs a fast path to a set-piece or toy that takes many presses, consider a reviewer-only
shortcut **only** if it is documented here and harmless; never hide functionality from review (guideline 2.3.1).

## 7. Screenshots (6, iPhone 6.9")

Use real captures from the 1.1 build (the existing CI `ScreenshotTests` + `Scripts/make_store_screenshots.py` pipeline
should be extended by the code agents; do not mock screens). Headline = the marketing line drawn above the capture.

| # | Headline (one line) | What is on screen |
| --- | --- | --- |
| 1 | Whatever you do, don't press it. | Home: the big red button, reaction line, three stats. The hook; must read at thumbnail size. |
| 2 | It has opinions about you. | Mid-run reaction from a later tier (e.g. run in the 50s) with the counter visible. |
| 3 | Push it far enough and it fights back. | A frame from the first "fights back" set-piece, at its most legible moment. |
| 4 | Hatch it. Pop it. Regret it. | Split capture: egg mid-hatch with a creature appearing, and the balloon about to pop. |
| 5 | One challenge a day. Keep the streak. | Daily challenge completed screen with the day streak visible. Use a seeded, believable streak and do not imply it is anyone else's score. |
| 6 | Collect every reaction. Share your shame. | Reactiondex with some entries discovered and some hidden, plus the new share card. |

Keep "private, offline, no ads" for the description instead of a screenshot this time; the 1.0 set used a whole slot on it.

**Capture pipeline (implemented, not yet run on CI at the time of writing).** `DontPressUITests/ScreenshotTests.swift`
adds the 1.1 captures `v11-egg-crack`, `v11-egg-hatch`, `v11-balloon`, `v11-balloon-pop`, `v11-setpiece-25`,
`v11-setpiece-50-lock`, `v11-daily`, `v11-reactiondex` and `v11-collection`; CI exports them by name to `ci-screenshots`.
`python3 Scripts/make_store_screenshots.py <captures dir> <out dir> --set v11` builds an 8-slide 1320x2868 set from
them (01-launch, set-piece, egg, balloon, daily, Reactiondex, the `07-share-card-847` v2 card render, and a closing
"No ads. No accounts." slide); `--set v10` (default) still builds the 1.0 set. Pick the 6 slides above from that output
(e.g. drop the closing slide, as noted). Missing captures skip their slide; nothing is mocked.

## 8. App preview video (15 seconds, portrait)

App previews must be captured from the app itself (screen recording of the real build; no live-action footage, no
device frames needed). Record on a simulator or device with Xcode/QuickTime, edit in iMovie or similar, then export to
the preview spec App Store Connect asks for at upload time. Sound on; the synthesized sounds carry it. No captions
claiming numbers you cannot prove.

| Time | Picture | Audio | On-screen text |
| --- | --- | --- | --- |
| 0.0 to 2.0 s | Static home screen, button centered. Nothing happens for a beat. | Silence | "Don't press it." |
| 2.0 to 4.5 s | Finger-down taps: press depth, counter ticks 1, 2, 3, reaction lines change. | Press sounds | (none) |
| 4.5 to 7.5 s | Fast cut to a high run: reactions escalate, milestone fires, the button fights back (first set-piece). | Set-piece sound | "It fights back." |
| 7.5 to 10.0 s | Toy switch: egg wobbles, cracks, creature hatches; quick cut to balloon inflating and popping. | Crack, pop | "Hatch. Pop." |
| 10.0 to 12.5 s | Daily challenge completed, streak increments; Reactiondex fills one new entry. | Short chime | "A new challenge every day." |
| 12.5 to 15.0 s | Back to the button, untouched. Reaction line: a fitting one from the catalog. Fade to app name. | Silence, then one press | App name |

Poster frame: choose the frame at about 5 s (mid set-piece), which is what people see before playing.

## 9. Release checklist for 1.1

- [ ] 1.0 approved (or rejection notes addressed) before submitting 1.1; do not stack changes on an unresolved rejection.
- [ ] Bump `MARKETING_VERSION` to 1.1 and `CURRENT_PROJECT_VERSION` to a new build number (code agents / owner).
- [ ] Every claim in sections 3 to 6 checked against the final build; `[OWNER: ...]` placeholders filled or removed.
- [ ] `docs/privacy.md` effective date set; App Privacy answer still "Data Not Collected" (re-check: no new SDKs, no network calls).
- [ ] `PrivacyInfo.xcprivacy` still accurate (UserDefaults `CA92.1`; add any new required-reason API the 1.1 code uses).
- [ ] In-app purchase metadata updated per PRO_2_0.md (if adopted) and submitted together with the 1.1 build.
- [ ] Age rating re-answered if any new content (cartoon creatures popping/hatching is not violence, but answer honestly).
- [ ] 6 new screenshots + optional preview uploaded; old 1.0 screenshots removed if they no longer match.
- [ ] Submit only when the owner decides to.


## Pro pricing (owner decision)
- Pro content in 1.1: Egg + Balloon toys, 4 alternate app icons, all 5 button styles right away (styles can still be earned).
- Suggested price: EUR 3.99 (one-time). Raise it in App Store Connect > In-App Purchases > DON'T PRESS Pro > Price Schedule when 1.1 is released. Existing buyers keep Pro (same product ID). No data supports one price over another; treat it as a test.
- Update the in-app-purchase review screenshot after the change (the offer now lists the toys and icons).
