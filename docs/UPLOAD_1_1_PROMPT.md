# Prompt: upload DON'T PRESS 1.1 (build 3) — paste into Claude Code in the Mac terminal

Run `cd ~/Desktop/don-t && claude`, then paste everything inside the block below.

```text
You are releasing DON'T PRESS 1.1 (build 3) from this repo (branch main). Work step by step, run real commands,
and report only what you actually ran. Do NOT submit anything for App Review and do NOT click "Submit": stop
before that and ask me. Never print or commit secrets, certificates or API keys. Answer me in Hebrew.

1. PREFLIGHT
   - `git checkout main && git pull origin main`; `git status` must be clean.
   - Check MARKETING_VERSION is 1.1 and CURRENT_PROJECT_VERSION is 3 in DontPress.xcodeproj/project.pbxproj.
     Ask me for the highest build number I already uploaded; if 3 is not higher, raise CURRENT_PROJECT_VERSION in
     Scripts/generate_xcodeproj.py, run `python3 Scripts/generate_xcodeproj.py`, and commit on a new branch (no push
     to main without asking).
   - Do not change the bundle ID (com.davidpitchkhadze.dontpress) or the Pro product ID
     (com.davidpitchkhadze.dontpress.pro). Do not overwrite my signing team: ask me to pick it in Xcode if missing.

2. TEST LOCALLY
   - `swift test` (Core logic).
   - `xcodebuild test -project DontPress.xcodeproj -scheme DontPress -destination 'platform=iOS Simulator,name=iPhone 16'`
     Report the exact result. If anything fails, stop and fix it before continuing.

3. ARCHIVE AND UPLOAD
   - `xcodebuild archive -project DontPress.xcodeproj -scheme DontPress -configuration Release -destination 'generic/platform=iOS' -archivePath build/DontPress.xcarchive`
   - If signing fails, tell me exactly what Xcode needs (Team, automatic signing). Then open the archive in the Xcode
     Organizer (`open build/DontPress.xcarchive`) and tell me to press Distribute App > App Store Connect > Upload.
     Do not attempt to bypass signing.

4. STORE SCREENSHOTS (1.1 set, already generated from real CI captures)
   - The 9 finished slides (1320x2868, 6.9") are in docs/appstore-1.1/ (01-dont ... 09-private). Open each PNG and
     check it: nothing cropped, no fake UI, numbers match the app. There is room for a 10th slide: the Pro offer
     (10-pro.png). Do NOT build it unless the price in the capture equals my real App Store price (the CI capture
     shows the test StoreKit price, $1.99). If I want it, ask me for the real price and regenerate the capture first.
   - To regenerate: `git fetch origin ci-screenshots && mkdir -p build/ci && git archive origin/ci-screenshots | tar -x -C build/ci`,
     then `python3 Scripts/make_store_screenshots.py build/ci docs/appstore-1.1 --set v11` (needs Pillow and the Inter font;
     adjust the FONT path locally, uncommitted). Never fabricate UI.

5. APP STORE CONNECT TEXT (I paste it myself; you do not have my credentials)
   - Write a file build/appstore-1.1-texts.txt from docs/RELEASE_1_1.md section by section: name, subtitle, promo
     text, description, keywords, What's New, App Review notes, and the Pro in-app purchase description.
   - Verify every claim against the code (toys unlock at 300 / 1,500 total presses or with Pro; Piñata needs Pro AND
     5,000 total presses; 5 button styles; 4 alternate icons; no ads, no accounts, no tracking). Fix any mismatch.
   - Counts and prices: say the Pro price is mine to set in App Store Connect; EUR 3.99 is only a suggestion.

6. CHECKLIST FOR ME (print it at the end)
   - New IAP review screenshot (the offer lists Egg, Balloon, Piñata gate, icons, styles).
   - Wait until 1.0 finishes review, then add build 3 to version 1.1 and press Submit myself.
   - Real-device checks I still owe: sound, haptics, Pro sandbox purchase, restore, refund -> classic icon.
   - Privacy label and docs/privacy.md still match the code (no tracking, UserDefaults only).

Final report: what you ran, exact results, what you did not verify, and what I must do by hand.
```
