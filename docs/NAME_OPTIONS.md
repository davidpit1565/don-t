# Store name options

Status: **options only. No name has been chosen, and none has been checked for availability or trademark conflicts.**
The owner decides after doing the checks at the bottom of this page.

Context: the exact name "DON'T PRESS" is already taken on the App Store, so the listing currently uses "DontPress".
The App Store name can be up to 30 characters. The name (with the subtitle and keywords) is indexed for search, so a
name that contains a search word ("button", "press") does some keyword work for free.

What changes with a new name, and what does not:
- **Unchanged:** bundle ID `com.davidpitchkhadze.dontpress`, the IAP product ID, SKU, ratings and history.
- **Changes in App Store Connect:** App Information → Name (localized per language). Submitted with a new version.
- **Optional code change (not done here):** the home-screen label (`CFBundleDisplayName`) and the in-app wordmark /
  share card. The home-screen label may differ from the store name, but keep them recognisably related.
- **Redo** the subtitle and keywords in RELEASE_1_1.md so they do not repeat words from the new name.

Character counts below were counted with a script (Python `len()`).

| # | Name | Chars | Pros | Cons |
| --- | --- | --- | --- | --- |
| 1 | Don't Press: Red Button Toy | 27 | Keeps the current brand and wordmark; adds two search terms ("red button", "toy"); smallest change. | Leans on a phrase other apps also use; "Toy" may read as a children's app. |
| 2 | The Forbidden Button | 20 | Clear, evocative, keeps "button" as a search term; works as a wordmark. | "Forbidden" is a common word in game titles; check for close matches. |
| 3 | Please Don't Press | 18 | Same joke, politer and distinct from "Don't Press"; fits the reaction voice. | Close to the taken name; could be judged confusingly similar by Apple or the other developer. |
| 4 | Big Red Nope | 12 | Short, funny, memorable; distinctive silhouette for a meme-style app. | Loses the literal "press/button" search words; "nope" is slang and may not translate. |
| 5 | Button of Bad Ideas | 19 | Original phrasing; matches the absurd tone and the escalating reactions. | Longer to say; "bad ideas" may be read as negative by some users. |
| 6 | Absolutely Do Not Press | 23 | Strong instruction, very on-brand; contains "press". | "Do Not Press" apps exist; the qualifier may not be enough to stand apart. |
| 7 | The Button Fights Back | 22 | Ties the name to the 1.1 headline feature; a story, not just a warning; good video hook. | Commits the brand to that feature; less obviously "a button you shouldn't press". |
| 8 | Hands Off the Red Button | 24 | Plain-language search words ("red button"); clear instruction. | Generic; harder to own as a brand or trademark. |

Notes, not recommendations:
- Names 2, 5 and 7 are the most distinctive (better for brand and trademark, weaker for literal search).
- Names 1, 6 and 8 carry the most search words (better for discovery, harder to protect and more likely to collide).
- Do not add another company's or app's name, and do not use Apple trademarks (guideline 2.3.7 and 4.1).

## Checks the owner must do himself (before choosing)

Nothing in this file was checked; availability can change at any time.

1. **App Store search** on an iPhone (and in other key storefronts if you can): search each candidate exactly and in
   close variants (with/without apostrophe, "Dont"/"Don't", singular/plural). Look for identical or confusingly similar
   names in the same space.
2. **App Store Connect:** the real test of availability is entering the name in App Information. Apple rejects names
   already in use. Do this only when you are ready to switch, because a name can be held by your app record once saved.
3. **Trademark search, United States:** USPTO trademark search (search the exact words and close variants, classes 9 for
   downloadable apps/games and 41 for entertainment services).
4. **Trademark search, European Union:** EUIPO eSearch plus, same classes. Consider TMview to cover national offices
   (for example the UK IPO) at once.
5. **Google Play and the web:** search the name to see if a known game, toy or brand already uses it.
6. **Domain and social handles** (optional): only if you plan a website or accounts for the app.
7. If anything looks close, ask a trademark attorney before committing; this document is not legal advice.

## Open question for the owner

Change the name with 1.1, or keep "DontPress" and rely on the keyword-led subtitle? Switching later is possible, but
each switch costs some recognition.
