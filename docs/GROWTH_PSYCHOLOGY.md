# Growth psychology: making DON'T PRESS worth sharing, honestly

Status: **strategy proposal.** Features marked *Built* were checked in code on `claude/v1.1` (`1fb876b`); everything
else is proposed. There are no performance numbers for this app, so none appear here. Claims without a source are
marked *unverified*. Related: [LAUNCH_PLAYBOOK.md](./LAUNCH_PLAYBOOK.md), [PRO_2_0.md](./PRO_2_0.md),
[RELEASE_1_1.md](./RELEASE_1_1.md).

The rule: **people share because a moment was funny, not because the app asked.** Nothing is gated on posting, rating
or inviting.

## 1. Why things spread, mapped to this app

| Principle (source) | Core idea | On screen, and when |
| --- | --- | --- |
| **Social currency** (Berger, *Contagious*, STEPPS, [jonahberger.com](https://jonahberger.com/books/contagious/)) | People share what makes them look clever or in on a joke. | Share card leads with a verdict, not a stat: "847 PRESSES. Officially unnecessary." The joke is on the sharer, so it is safe to post. |
| **Triggers** (STEPPS) | Everyday cues bring a product to mind. | Daily challenge (*Built*): "Today's rule: press it exactly 13 times." Real red buttons (lifts, crossings) are free cues; clip format "Every red button now." |
| **High-arousal emotion** (Berger & Milkman 2012, [doi:10.1509/jmr.10.0353](https://doi.org/10.1509/jmr.10.0353)) | Amusement, awe, anxiety get shared more than low-arousal feelings. | Set-pieces are sudden reversals (the button runs away at 25). Keep them under 5 s, with sound and haptic. |
| **Public** (STEPPS); "show the product in use", Red Bull-style (practitioner lore, *unverified*) | Visible things get imitated. | The button is in frame 1 of every clip and every card. Apple requires store media to show the app in use (2.3.3). |
| **Practical value** (STEPPS) | Useful things get passed on. | Weak fit; be honest. "Something to press that isn't Send." No stress-relief or health claims. |
| **Stories** (STEPPS) | Ideas travel inside narratives. | A run is a story from The Flinch (10) to The End of the Button (1000, *Built*: "Starring: you. Also starring: your thumb."). |
| **Curiosity gap** (Loewenstein 1994, [doi:10.1037/0033-2909.116.1.75](https://doi.org/10.1037/0033-2909.116.1.75)) | A specific, visible gap motivates closing it. | Hidden Reactiondex entries as "???" with "Discovered N/M"; locked set-pieces listed as "??? at 250". Hook: "What happens at 1,000?" |
| **Variable reward** (operant conditioning) | Unpredictable rewards sustain behaviour; also the core of compulsive design, so cap it. | Egg rarity (5% legendary, 25% rare) and balloon popping at a hidden 6 to 14 taps (*Built*). Odds shown; never sold per roll. |
| **Goal gradient** (Kivetz, Urminsky & Zheng 2006, [doi:10.1509/jmkr.43.1.39](https://doi.org/10.1509/jmkr.43.1.39)) | Effort speeds up near a goal. | Thin bar under CURRENT RUN, visible only in the last 20% before a milestone: "7 to go. Don't." |
| **Endowed progress** (Nunes & Drèze 2006, [doi:10.1086/500480](https://doi.org/10.1086/500480)) | A head start raises completion. | Press 1 already earns "Weak Moment" (*Built* achievement) and a first Reactiondex entry, so meters start above zero, honestly. |
| **Endowment / IKEA effect** (Kahneman, Knetsch & Thaler 1990, [doi:10.1086/261737](https://doi.org/10.1086/261737); Norton, Mochon & Ariely 2012, [doi:10.1016/j.jcps.2011.08.002](https://doi.org/10.1016/j.jcps.2011.08.002)) | People value what they own or made. | Hatched creatures are "yours" and can appear on the card ("Hatched: The Long Tuesday"). Never put them at risk. |
| **Self-expression** (Tamir & Mitchell 2012, [doi:10.1073/pnas.1202129109](https://doi.org/10.1073/pnas.1202129109)) | Talking about yourself is intrinsically rewarding. | User picks an earned title for the card: "Certified Non-Listener". |
| **Peak-end** (Kahneman et al. 1993, [doi:10.1111/j.1467-9280.1993.tb00589.x](https://doi.org/10.1111/j.1467-9280.1993.tb00589.x)) | Experiences are remembered by peak and end. | Set-pieces end on their best line (*Built*: "Game over. Press to disagree."). Surface Share right after a peak. |
| **No-spoiler share** (Wordle's emoji grid, invented by players and then added to the game, preceded its spread: [Wikipedia](https://en.wikipedia.org/wiki/Wordle)) | Show *that* you did it, not *what* happened. | Daily card: "DON'T PRESS · Day 112 · done in 1 try · streak 9", without the rule. Recipients must open the app to see it. |

Precedent: Wordle's author also built Reddit's 2015 *The Button*, a single button that became a mass event
([Wikipedia](https://en.wikipedia.org/wiki/The_Button_(Reddit))). A button with a rule is a proven social object.

## 2. Moments worth filming

Each starts with the button in frame and works in 6 seconds without context.

| # | Trigger | What the viewer sees | Status |
| --- | --- | --- | --- |
| 1 | Run 10 | Button flinches: "Nope." then "Fine. Fine." | Built |
| 2 | Run 25 | Button slides off screen ("I'm leaving."), comes back ("I have nowhere else to go.") | Built |
| 3 | Run 50 | Lock bar fills to 100%, then "Lock failed. It never had a lock." | Built |
| 4 | Run 100 | Glitch bands, "sys: button.integrity = low", "Repaired. Unfortunately." | Built |
| 5 | Run 250 | Tremor, "That was the button clearing its throat." | Built |
| 6 | Run 500 | "GAME OVER", "(not really)", "There is no game. Continue." | Built |
| 7 | Run 1000 | End credits on the button. | Built |
| 8 | Egg hatches a legendary (5%) | Shake, crack, "Chairman Egg: hatched from an egg. Is also an egg." | Built |
| 9 | Balloon (pops at a hidden 6 to 14 taps) | Slow inflate, wince per tap, pop. | Built |
| 10 | Daily "exactly N", overshoot by one | Counter hits N+1, fail screen. | Built |
| 11 | First press ever | Long silent hover, then the first reaction. | Built |
| 12 | Tapping during The Getaway | Taps still count while it flees (*Built*, UI-tested); add caption "You pressed a fleeing button." | Proposed copy |
| 13 | Last Reactiondex entry | Meter hits M/M; a closing line. | Proposed |
| 14 | Run 777 | Button becomes a slot reel that only shows "NO NO NO". | Proposed |
| 15 | Return to the app mid-run | "Oh. You're back." Once per session; never a notification. | Proposed |

**Record-friendly mode** (proposed Settings toggle, off by default): hides the status bar and unlock banners; draws a
touch ripple (screen recordings do not show touches); keeps button and reaction in the middle band of a 9:16 frame, clear
of TikTok/Reels caption and button overlays (overlay sizes vary, *unverified*: test with an upload); reaction text one
size larger; sound on. It never fakes counts, seeds a run or skips to a set-piece; sped-up footage gets labelled.

## 3. Share loops that never gate anything

**Card** (*Built*): portrait; button, number, one verdict line, optional title, small app name. Variants: personal
best, daily (no-spoiler), creature. No upsell watermark, no rank. **Clips:** no in-app video export in 1.x; rely on iOS
Screen Recording plus record-friendly mode.

**"Beat my 847" without a backend:**

| Tier | How | Infra | Caveats |
| --- | --- | --- | --- |
| A (start) | Share sheet sends the card plus "I pressed it 847 times. I was told not to. Beat that:" and an App Store campaign link | None | The challenge lives in the post, not the app. |
| B | "Challenge" sheet: recipient types the number from a card; the run shows a "Beat 847" line | None | Self-reported; label it "their claim". |
| C | Universal link `https://<domain>/c?t=847` on a static page with `apple-app-site-association` ([Apple](https://developer.apple.com/documentation/xcode/supporting-universal-links-in-your-app)). Installed: opens B prefilled. Not installed: page offers the App Store link | Static hosting at a domain root (a GitHub *project* page under `/don-t/` will not work) | No deferred deep link without an attribution service: page says "Installed? Tap the link again." Host logs exist: mention in the privacy policy. Clamp `t` to 1 to 1,000,000; no names or free text. |

A link must **never unlock content or rewards** (3.1.1 bans custom unlock mechanisms such as codes). **"Post a video to
unlock X" cannot be verified without a backend** (the app cannot see what was posted), and it conflicts with 3.1.2(a)
and 3.2.2(x). Do not do it.

**Apple rules**, quoted from [the App Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
("Last Updated: October 16, 2026"; read 2026-11-01):

- **3.2.2 (x):** "Apps must not force users to rate the app, review the app, download other apps, or other store-related
  actions in order to access functionality, content, or use of the app. Apps may otherwise incentivize users to take
  specific actions within apps (such as by completing a level or watching an ad)."
- **Section 3 note:** "If we find that you have attempted to manipulate reviews, inflate your chart rankings with paid,
  incentivized, filtered, or fake feedback, or engage with third-party services to do so on your behalf, we will take
  steps to preserve the integrity of the App Store, which may include expelling you from the Apple Developer Program."
- **3.1.2(a)** (in the subscriptions section): "As with all apps, those offering subscriptions should allow a user to
  get what they've paid for without performing additional tasks, such as posting on social media, uploading contacts,
  checking in to the app a certain number of times, etc."
- **3.1.1:** "If you want to unlock features or functionality within your app, (by way of example: subscriptions,
  in-game currencies, game levels, access to premium content, or unlocking a full version), you must use in-app
  purchase. Apps may not use their own mechanisms to unlock content or functionality, such as license keys, augmented
  reality markers, QR codes, cryptocurrencies and cryptocurrency wallets, etc." And: "Apps offering "loot boxes" or
  other mechanisms that provide randomized virtual items for purchase must disclose the odds of receiving each type of
  item to customers prior to purchase."
- **2.3:** "Customers should know what they're getting when they download or buy your app, so make sure all your app
  metadata, including privacy information, your app description, screenshots, and previews accurately reflect the app's
  core experience". **2.3.1(a):** "marketing your app in a misleading way ... whether within or outside of the App Store,
  is grounds for removal" (this covers TikTok clips).
- **4.2:** "If your App doesn't provide some sort of lasting entertainment value or adequate utility, it may not be
  accepted." **4.3(b)** names "sound effects" as saturated and "fart, and burp apps" as low-effort. Set-pieces, toys and
  the daily challenge are the defence; never paywall all of them.
- **5.6:** "Apps should never prey on users or attempt to rip off customers, trick them into making unwanted purchases,
  force them to share unnecessary data, raise prices in a tricky manner, charge for features or content that are not
  delivered, or engage in any other manipulative practices within or outside of the app." **5.6.1:** "Use the provided
  API to prompt users to review your app". **5.6.3:** "Manipulating any element of the App Store customer experience
  such as charts, search, reviews, or referrals to your app erodes customer trust and is not permitted."

Avoid: rewards for sharing, rating or inviting; "share to continue"; prefilled text claiming rank. The system review
prompt ([`requestReview`](https://developer.apple.com/documentation/storekit/requesting-app-store-reviews)) is fine,
unconditionally, after a peak (e.g. The End of the Button), never after a fail.

## 4. Ethical Pro conversion

**Current state (code):** `isToyUnlocked` returns `!kind.requiresPro || isPro`, so egg and balloon are **Pro-only
today**, not press-gated. PRO_2_0.md said toys stay free; RELEASE_1_1.md now sells them. Settle this first.

**When to ask:** tapping a locked toy, style or icon (full sheet, *Built*); after a set-piece at run 100+ (one small
dismissible line, at most once per 7 days); opening a Pro-only Reactiondex page (inline preview). **Never:** at launch,
mid-run, after a fail, twice in a session, or two days running unprompted. "Not now" is as large and legible as
"Unlock".

**Copy (honest, in voice):**
1. "Pro. More ways to make the button worse."
2. "One payment. No subscription. The button hates subscriptions."
3. "The egg, the balloon and four icons. That's the whole list."
4. "Everything you earned stays yours, Pro or not."
5. "It's {price}, once. That's the actual price."
6. "Legendary hatch odds: 5%. Rare: 25%. Pro doesn't change them."
7. "Not now is a perfectly good answer."
8. "Bought it before? Restore Purchases. The button forgets. Apple doesn't."
9. "Pro doesn't make you better at pressing. Nothing could."
10. "Supports one developer and zero ads."

**Never:** countdowns, "today only", fake strikethrough prices, "only 3 left", guilt ("The button is disappointed"),
confirmshaming ("No thanks, I like boring things"), delayed or tiny close buttons, randomized paid items. Catalogue:
[deceptive.design](https://www.deceptive.design/types).

**Critique of egg 300 / balloon 1,500 / mythic piñata 5,000 total AND Pro.** Assumptions, not data (*unverified*):
fast tapping about 5 taps/s; a casual player presses 50 to 150 times on days they open the app; most players never
return after day 1.

| Gate | At 5 taps/s nonstop | 100 presses/day | 50 presses/day |
| --- | --- | --- | --- |
| Egg 300 | 1 min | day 3 | day 6 |
| Balloon 1,500 | 5 min | day 15 | day 30 |
| Piñata 5,000 | 17 min | day 50 | day 100 |

The gates cost little time but much patience, so they reward grinding over play. Most players would never see the
balloon, which weakens screenshots and the 4.2 case. The piñata double gate lets someone pay and still not have it,
acceptable only if the offer says so before purchase (5.6: "charge for features or content that are not delivered").

**Adjusted ladder:** mirror the existing style model, "earn it by playing, or Pro right away".

| Item | Free path | Pro |
| --- | --- | --- |
| Egg | 100 total presses (session 1) | Immediately |
| Balloon | 750 total presses (about day 5 to 8 at the assumptions) | Immediately |
| Piñata | None (Pro toy) | Immediately |
| Mythic piñata look | None | Cosmetic, at 5,000 total; stated on the offer |

## 5. Retention without dark patterns

- **Streak with freeze** (*Built*: one per 7 days, used automatically on a single missed day): "Your streak froze
  instead of breaking. You're welcome." No paid freezes, no notifications. Duolingo frames its freeze as a habit aid
  ([blog](https://blog.duolingo.com/how-duolingo-streak-builds-habit/)).
- **Daily challenge** (*Built*): under a minute; failing costs only the day's tick.
- **Meters:** "Reactions N/M", "Creatures 9/13", "Set-pieces 4/7". Every free entry is reachable by play.
- **No loss framing:** no "you will lose", no decaying rewards.

**Measurement with no SDK** (the app sends nothing; privacy label stays "Data Not Collected",
[Apple](https://developer.apple.com/app-store/app-privacy-details/)):

| Question | Source |
| --- | --- |
| Which platform drives installs? | One campaign link per profile bio ([Apple](https://developer.apple.com/help/app-store-connect/view-app-analytics/manage-campaign-links/)); read [acquisition sources](https://developer.apple.com/help/app-store-connect/view-app-analytics/view-acquisition-sources/). Opt-in data, so partial. |
| Which pitch converts? | Custom product pages per clip theme ([Apple](https://developer.apple.com/app-store/custom-product-pages/)). |
| Does Pro sell? | App Store Connect sales and proceeds by version. |
| Which clips work? | Spreadsheet: clip, hook, moment #, views, watch-through, shares, saves, link clicks. |
| Do people share cards? | Only indirectly (tags, comments). Do not add share counting. |

## 6. Four-week experiment plan

| Week | Post | Change | Measure / decide |
| --- | --- | --- | --- |
| 1 | 5 clips: moments 1, 2, 3, 6, 9; hook "It said don't." | Campaign links per platform | Watch-through and shares per clip. No decisions. |
| 2 | Same moments, new hooks ("What happens at 1,000?", "POV: the button left") | Tier A share text; record-friendly mode if built | Hook vs hook on share rate, moment held constant. |
| 3 | Daily series "Day N" with the real streak | One custom product page matching the best theme | Conversion: default page vs custom page. |
| 4 | Two best formats only, plus one hatch clip | Pro copy from section 4; Tier B challenge | Pro proceeds vs weeks 1 to 3 (noisy; one change at a time). |

Change one thing per week, log the date of each change, judge by watch-through and share rate rather than views, and
keep real numbers in the spreadsheet, not in this doc.
