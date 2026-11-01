# Launch playbook: short video (TikTok, Instagram Reels, YouTube Shorts)

For a solo developer with no budget, around version 1.1. Honest framing: **most short videos get little reach, and
there is no way to predict which one will travel.** The plan below is built to be cheap to repeat, so you can post many
times and learn from your own numbers. There are **no performance figures in this document**; anything that looks like
a benchmark is marked *unverified* and should be replaced by what you measure.

Features referenced here are planned for 1.1 (set-pieces, egg, balloon, daily challenge, Reactiondex, sounds). Only film
what is in the build people can download when the clip goes up; a clip showing something the app does not do will earn
angry comments and could count as misleading advertising.

## Principles

1. **The app is the hook.** A red button that says "don't" is a joke anyone gets with the sound off in one second. Lead
   with the button on screen in the first frame, not a logo or a talking intro.
2. **Real screen recordings, real sounds.** Record the app (iOS Screen Recording or a simulator capture) and, for some
   clips, a phone held in hand. Do not stage fake reactions, fake comments or fake "downloads" counters.
3. **One idea per clip, under about 15 seconds.** Short clips are cheap to make, so you can post often.
   (*Unverified:* the common advice that shorter clips are rewarded by these platforms. Test it with your own data.)
4. **Use the in-app sounds**, or audio the platform licenses for that use. Do not add copyrighted music outside the
   platform's library.
5. **No claims you cannot back.** No "#1 app", no world rankings, no invented user counts. "Free, no ads" is true;
   say it.

## Clip ideas tied to actual features

Each idea is a format you can repeat many times with different moments.

| # | Clip | Built on | Shot |
| --- | --- | --- | --- |
| 1 | "It said don't." A finger hovers over the button for an uncomfortably long time, then presses. Cut on the first reaction line. | Button + reactions | Phone in hand, close-up. |
| 2 | "Reactions ranked by how personally attacked I felt." 4 reaction lines from different tiers, one per beat. | Reaction catalog | Screen recording with text overlay. |
| 3 | "What happens at 100 presses?" Speed-ramp a run, slow down for the "button fights back" set-piece. | Set-pieces | Screen recording; the payoff in the last 3 seconds. |
| 4 | "POV: you were told not to press the egg." Egg wobbles, cracks, a creature appears. End on the creature's reaction. | Egg toy | Screen recording, sound on. |
| 5 | "How long can you hold off popping it?" Balloon inflates press by press; pop at the end. | Balloon toy | Screen recording; build tension. |
| 6 | "Day N of the daily challenge." Short daily series showing today's challenge and the streak counter. | Daily challenge + streak | Same framing every day so it is recognizable. Use your real streak. |
| 7 | "Reactiondex: still missing one." Scroll the collection, stop on a hidden entry, then go find it. | Reactiondex | Screen recording. |
| 8 | "Sound on." Press sounds, pop, hatch, set-piece; a pure audio-satisfaction clip. | Synthesized sounds | Screen recording, no text after the first second. |
| 9 | "I made an app that insults you for pressing a button." Founder clip: who you are, one line about building it solo, then the button. | Everything | Face to camera, 10 seconds max. |
| 10 | "Share card reveal." Hit a personal best, render the share card, show it. Invite people to post theirs. | Share card | Screen recording. Never imply a global leaderboard. |
| 11 | "Reacting to a reaction." Read a line out loud like it is a serious review of your life choices. | Reactions | Face to camera. |
| 12 | "Building it" (devlog): a 10-second look at how a set-piece or sound was made. | Any 1.1 feature | Screen capture of Xcode + result. |

Hooks to rotate in the first second (text overlay): "Don't.", "It warned me.", "Why does a button have opinions",
"Day 1 of not pressing the button" (then press).

## Cadence

Pick a level you can sustain for 6 weeks. Consistency matters more than volume for a solo developer.

| Phase | When | What |
| --- | --- | --- |
| Before 1.1 | 1 to 2 weeks before release | 3 to 5 devlog/teaser clips (#9, #12). Do not promise a date you cannot hit. |
| Launch week | Release day to day 7 | 1 clip per day, rotating #1, #3, #4, #5, #8. Pin the best one. |
| Weeks 2 to 6 | After launch | 3 to 5 clips per week. Keep the daily-challenge series (#6) if it gets any traction; drop formats that do nothing. |
| Ongoing | Every update | One clip per new set-piece, toy or creature. |

Post the same clip on TikTok, Reels and Shorts (remove other platforms' watermarks; export the original). Batch-record
on one day per week to keep it manageable.

## What to measure

Use what each platform and App Store Connect actually give you; record it in a simple spreadsheet, one row per clip.

Per clip (platform analytics):
- views, average watch time / percentage watched, shares, saves, comments, profile visits;
- which hook and which feature the clip used (your own tag).

For the app (App Store Connect → Analytics; data comes from users who agree to share it with developers, so it is a
partial view):
- impressions, product page views, first-time downloads, conversion rate from product page to download;
- in-app purchase proceeds and Pro purchases by app version (to judge PRO_2_0.md);
- sources: App Store Connect lets you create **campaign links** (with a campaign token) for the App Store URL; use a
  different one per platform in your profile link so you can tell TikTok from Instagram traffic. Generate them in App
  Store Connect; do not hand-build URLs from memory.

Ratings and reviews: read every one; reply to the critical ones calmly from App Store Connect.

How to decide:
- After about 10 clips, compare formats by **share rate** and **watch-through**, not raw views (a single lucky clip
  skews views). *Unverified:* the general advice that shares and watch time are stronger signals than likes.
- Double down on the two best formats; stop the two worst.
- If clips get views but downloads do not move, the gap is the store page: revisit screenshot 1, the subtitle and the
  preview video (RELEASE_1_1.md), not the videos.

## Things to avoid

- Buying followers, views or reviews; review swaps; incentivized reviews (against Apple's rules and platform rules).
- Asking for ratings outside the system prompt in the app (`SKStoreReviewController`-style prompts are fine if the
  code agents add one; never offer rewards for ratings).
- Fake "my friend's reaction" clips that are actually staged without saying so.
- Paying creators without the platform's paid-partnership / ad disclosure.
- Any claim of a global ranking or "most-pressed button in the world".

## Open questions for the owner

1. Will you appear on camera (clips #9, #11), or screen-only?
2. Which accounts post: a personal account or a new app account? (A personal "solo dev" voice is often easier to grow,
   *unverified*.)
3. Do you want an in-app review prompt in 1.1 (code change, not in this doc)?
