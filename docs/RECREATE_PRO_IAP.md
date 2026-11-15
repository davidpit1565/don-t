# Recreate the Pro in-app purchase (new product ID)

Why: the first IAP (`com.davidpitchkhadze.dontpress.pro`) is stuck on the rejected 1.0 submission (Guideline 2.3.2,
promotional image = app icon) and its image cannot be replaced. Apple does not allow a deleted product ID to be used
again, so the app now uses **`com.davidpitchkhadze.dontpress.pro2`**. The app code (`ProStore.productID`) and
`DontPress.storekit` were changed to match. The app was never released, so no buyer loses anything.

## In App Store Connect (owner does this)
1. Delete or ignore the old IAP "DON'T PRESS Pro" (`...pro`). Do not reuse its ID.
2. Monetization > In-App Purchases > "+" > **Non-Consumable**.
   - Reference Name: `DON'T PRESS Pro`
   - Product ID: `com.davidpitchkhadze.dontpress.pro2` (exactly)
   - Price: your choice (EUR 3.99 is only a suggestion)
   - Availability: all countries you want
   - Localization (English U.S.): Display name `DON'T PRESS Pro`; Description: `Toys, button styles and app icons, once.`
   - Image: upload `docs/appstore-1.1/iap-promo-1024.png` (egg + balloon + styles; NOT the app icon).
   - Review screenshot: a real screenshot of the Pro offer from the build you submit.
   - Review notes: `Tap the trophy icon, then a locked button style, toy or icon to see the Pro offer.`
   - Leave "Promote on the App Store" off unless you want it.
3. The app version (never released): set the version to **1.1** (App Store Connect > the version number), upload the
   build from `main` (version 1.1, build 3 or higher), select it, and attach the new IAP in the version's
   "In-App Purchases and Subscriptions" section.
4. Update version metadata from `docs/RELEASE_1_1.md` and screenshots from `docs/appstore-1.1/`.
5. Reply to the old App Review message briefly (new IAP created, old one removed), then Submit for Review yourself.

Nothing here is submitted automatically.
