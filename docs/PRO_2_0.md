# Pro 2.0: repositioning the optional purchase

Status: **proposal for the owner to decide.** Nothing here is implemented. Prices are suggestions, not data: there are
no sales figures for this app yet, so nothing below is based on measured conversion.

## The problem

In 1.0, Pro (`com.davidpitchkhadze.dontpress.pro`, non-consumable, about $1.99 / €1.99) does exactly one thing:
"Unlock all button styles right away." Every one of those styles can also be earned for free by playing. A critical
review called that weak, and it is: it sells *impatience*, it has nothing a player can see before buying, and it
has nothing to do with the 1.1 features people will actually talk about (sounds, toys, set-pieces, the Reactiondex).

## The proposal in one line

**Pro = more ways to make the button worse.** Sound packs, animated skins, extra toys and Reactiondex extras, bought
once, forever. The core loop, the daily challenge and the share card stay free. No ads, no subscription, ever.

## What must stay free (non-negotiable)

These are what get the app reviewed fairly (guideline 4.2), shared (the share card is marketing), and kept (the streak):

| Free forever | Why |
| --- | --- |
| The button, counters, all reactions, milestones and "the button fights back" set-pieces | This *is* the app. Paywalling it would also weaken the 4.2 case. |
| The daily challenge and day streak | Habit loop. A paywalled streak breeds resentment and 1-star reviews. |
| The share card (including the 1.1 redesign) | Every share is free distribution. Never watermark it as an upsell. |
| The two 1.1 toys: egg and balloon | They are the headline of 1.1 and of the screenshots/preview. |
| The base Reactiondex (every entry discoverable by playing) | Collecting is the retention mechanic. |
| The 5 button styles from 1.0, still earnable by playing | Taking away a free path that already shipped would be a bait-and-switch. |
| Restore Purchases, privacy, no ads | Obvious. |

## What Pro adds (candidates; ship only what is built)

Ordered by how visible and "shareable" each one is relative to build cost:

1. **Sound packs.** Alternative synthesized sets for presses, pops, hatches and set-pieces (for example: "Arcade",
   "Office", "Orchestra Hit", "Very Small Kazoo"). Cheap to make because 1.1 already synthesizes sound; obvious in a
   15-second clip.
2. **Animated button skins.** Styles that move: a pulsing core, a cracked surface that spreads with the run, a
   melting button. Distinct from the 5 static styles, which stay free.
3. **Extra toys.** One or two Pro-only toys beyond the egg and balloon (earnable free by play; the piñata shipped in 1.1 as Pro + 5,000 presses) (ideas: a self-destruct lever, a
   jack-in-the-box). Each toy is a feature a reviewer can see, so it also supports 4.2.
4. **Reactiondex extras.** A Pro-only page of bonus reactions/creatures, alternate "shiny" creature colors, and a
   collection filter. The base Reactiondex must remain fully completable for free; Pro adds *extra* entries,
   it does not lock the free ones.
5. **Everything from 1.0 Pro**: all 5 styles unlocked right away (existing buyers were promised this; keep it).

Rules for the extras:
- Pro content is **fixed and listed**, not random. If any Pro item were randomized and sold, guideline 3.1.1 would
  require disclosing the odds; avoid that entirely by selling a known bundle.
- The Pro screen shows a preview of every item (play a sound pack sample, show a skin animating) before purchase.
- No timers, no "only today" pressure, no fake discounts.

## Price recommendation

| Option | Price (USD equivalent; Apple sets local prices per territory) | When |
| --- | --- | --- |
| Keep | $1.99 | If 1.1 ships with only one or two of the extras above. |
| **Recommended** | **$2.99** | Once Pro contains at least: one sound pack, two animated skins, one extra toy. |
| Later | $3.99 | Only if Pro keeps growing in later updates. Do not raise it in the same update that adds content. |

Reasoning (judgement, not data): a one-time unlock for a toy app usually sits in the low single dollars; $2.99 is easier
to justify once there is something to *see and hear* before buying. Changing the price does not affect people who
already bought. Test the price by watching your own App Store Connect numbers (proceeds, IAP conversion by version), not
by guessing; see LAUNCH_PLAYBOOK.md.

Not recommended: subscriptions (nothing recurring to justify them, guideline 3.1.2 expects ongoing value), ads (contradicts
the privacy page and the product), tip-jar consumables (fine later, but they do not fix the "what do I get" problem).

## App Store Connect setup changes

### Recommended: keep the existing product ID

Keep **`com.davidpitchkhadze.dontpress.pro`** as the single Pro product and expand what it unlocks in the app.

What you do in App Store Connect (Monetization → In-App Purchases → DON'T PRESS Pro):

1. **Do not delete or recreate the product.** Product IDs can never be reused after deletion, and the product type
   (non-consumable) cannot be changed.
2. **Edit the localization**: display name can stay "DON'T PRESS Pro" (change it if the store name changes, see
   NAME_OPTIONS.md); new description (55 characters max for the IAP description field, check the counter in App Store
   Connect), for example:
   `Sound packs, animated skins, extra toys, bonus entries.` (55 characters, counted)
3. **Change the price** (Price Schedule) to the chosen point. The change applies to new purchases only.
4. **Replace the review screenshot** with one of the new Pro screen from a TestFlight build.
5. **Update the review notes** for the IAP: where the offer is, what it unlocks, and that the free content is unaffected.
6. **Submit the updated IAP with the 1.1 version** (version page → In-App Purchases and Subscriptions). Metadata
   changes to an approved IAP go through review again.
7. **Family Sharing:** decide deliberately. Once turned on for a product it cannot be turned off.

What the code must do (for the code agents, not this doc): the entitlement check stays "does the user own
`...dontpress.pro`", and that single flag unlocks the whole Pro 2.0 set. The cached `dontpress.isPro` value keeps
working. No migration is needed.

**Implications for existing 1.0 buyers:** they own the same product ID, so they automatically get everything Pro 2.0
adds, at no extra cost, on update or via Restore Purchases. This is the honest choice (their purchase was "Pro", not
"styles only"), it costs little because the 1.0 buyer base is small, and it avoids any support burden. Mention it in
What's New only if you want to ("Already have Pro? Everything new is yours.").

### Alternative: separate products (not recommended now)

Create new non-consumables, for example `com.davidpitchkhadze.dontpress.pack.sounds1`,
`com.davidpitchkhadze.dontpress.pack.toys1`, and keep `.pro` as the styles unlock.

- Pros: can price each pack; can add packs later without changing what Pro means.
- Cons: more review work per product (each needs metadata, screenshot, review); more StoreKit code and restore cases;
  a "Pro" that does not include the new stuff feels like a downgrade to people who already bought it; splits an already
  small audience across several buttons.
- If you ever go this way, do it *in addition to* the recommended setup: Pro stays the all-in bundle, and packs are
  cheaper single purchases. Then Pro must include every pack (and say so) so no buyer pays twice.

## Open questions for the owner

1. Which extras will actually be built for 1.1? The Pro description and price should follow what ships.
2. $1.99 or $2.99 at the 1.1 launch?
3. Family Sharing on or off (irreversible once on)?
4. Does the Pro display name change with the store name?
