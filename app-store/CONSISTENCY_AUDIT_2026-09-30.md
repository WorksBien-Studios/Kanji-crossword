# Kanji Crossword consistency audit — 2026-09-30

Decision: **BLOCKED for submission; listing metadata uploaded and read back successfully.** Screenshots and previews were excluded from this task. App Review has not been requested. App Store Connect version 1.0 remains Prepare for Submission. No review approval or search-ranking guarantee is asserted.

## Verified facts and conflicts resolved

| Claim | Verified value | Evidence |
|---|---|---|
| App identity | 6817388023; com.gooduse.kanjicrossword; 1.0 | Live app/version API, release app map |
| Processed build | 1; 8aa64597-afd7-4d22-8016-ec81b673c12c; VALID; attached to version | Build and version relationship APIs |
| Platforms/language | iPhone/iPad; iOS/iPadOS 18.0+; Japanese UI and content | App project, Info.plist, UI source, processed build |
| Puzzle library | 360; standard 240, large 120; 90 in each difficulty | Bundled JSON, PuzzleCatalog, exhaustive release tests |
| Free boundary | 30 spread across modes/difficulties | PuzzleAccessPolicy and PuzzleCatalog.freePuzzleIDs |
| Commerce | One non-consumable; com.gooduse.kanjicrossword.pro.lifetime; ¥1,000 Japan | Source product ID, live IAP 6817793709, price point, availability |
| Download/availability | Free; Japan only; future territories disabled | Live app price and all territory availability rows |
| Additional devices | Apple silicon Mac and Vision Pro disabled | Pricing/Availability UI checkboxes |
| History | Available in free and paid versions | Ungated 記録 tab; listing and IAP disclosures corrected |
| Offline scope | Bundled gameplay; Apple connection needed for purchasing/restoring | Runtime, StoreKit source, listing and support |
| Data | Local SwiftData records/preferences; Keychain entitlement cache; native backup subject to device settings | Runtime/persistence, privacy manifest, deployed privacy policy |
| Tracking/SDKs | No ads, analytics, tracking, account or developer backend | Package inventory/source/manifest; published Data Not Collected label |
| Legal | Apple standard EULA; JMdict/EDRDG attribution and CC BY-SA 3.0 | Live EULA record has no custom agreement; app LicensesView; content attribution |
| Age rating | 4+ (FOUR_PLUS) | Current questionnaire saved; live app-info response |
| Review access | No login/hardware; EN and JA navigation notes saved | Live review-detail API and listing UI |
| Review contact | Incomplete | Kanji app's own review record/UI contains blank fields |

Source audited: 53f088a8c6843cd65a1955e1f28f87c6f56feb22. Metadata tooling subsequently added in b0b9c0cb7754ae316f5c4c8adecb4197f44457c5 does not change gameplay or the processed build.

## Uploaded fields and ASO rationale

Canonical copy and repeatable API configuration are in `LISTING_MANIFEST.json`; the existing `scripts/asc_listing_sync.rb` and `.github/workflows/app-store-listing.yml` support future uploads with the organization key route. Corrected price-read relationship names to the singular names in Apple’s current OpenAPI schema. Metadata-only uploads now report missing review-contact fields as pending while continuing the authorized commerce sync; no contact details are copied or guessed. Submission remains blocked.

| Field | Saved value/count |
|---|---|
| Name | 漢字ナンクロ 広告なし — 11/30 characters |
| Subtitle | 大きな文字でじっくり脳トレ・漢字クロスワードパズル — 25/30 |
| Description | 940/4,000 characters; clear 30-free boundary, one-time unlock, Japanese language, purchase connectivity, free history, privacy and EULA URLs |
| Promotional text | 76/170 characters |
| Keywords | シニア,頭の体操,熟語,語彙,暇つぶし,漢クロ,読み方,初心者,オフライン — 95/100 UTF-8 bytes |
| Category | Games; Word and Puzzle subcategories |
| Rights | USES_THIRD_PARTY_CONTENT |
| URLs | All three canonical Japanese marketing, support and privacy pages return actual app-specific content |

Current Japanese App Store listings show the vocabulary 漢字ナンクロ, 大きな文字, 脳トレ and 漢字クロスワードパズル. Those are observed phrases, not proof of private keyword volumes. Removed unsupported assertions about exact ranking weights and preferred subtitle length. Removed 難読 because this release does not establish a dedicated difficult-reading feature; offline play is directly supported. No competitor brand keywords, static purchase prices in public copy, medical benefits, definitions, cloud sync or unlimited new-puzzle promises were added.

Observed sources:
- https://apps.apple.com/jp/app/id1527701421
- https://apps.apple.com/jp/app/id714547064
- https://apps.apple.com/jp/app/id1509623972

## Public pages and EULA

- https://worksbienstudios.com/apps/kanji-crossword/
- https://worksbienstudios.com/apps/kanji-crossword/support/
- https://worksbienstudios.com/apps/kanji-crossword/privacy/
- https://www.apple.com/legal/internet-services/itunes/dev/stdeula/

The description's exact EULA URL was read back from the API and visually confirmed in the editable App Store Connect description. Its destination was opened and displayed Apple's standard EULA. The support page has a real email contact, restoration/offline guidance and EULA link. The privacy policy accounts for voluntary support correspondence and native backup, rather than making an absolute no-data-ever claim.

App Privacy was saved and published via the signed-in UI because Apple's current public OpenAPI specification exposes no App Privacy questionnaire endpoint. UI showed "Published a few seconds ago" and "Data Not Collected". Evidence: `evidence/privacy-published-2026-09-30.jpg`.

## Apple requirements checked

Primary sources reopened on 2026-09-30:
- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/
- https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information
- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy
- https://developer.apple.com/app-store/discoverability/
- https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-in-app-purchase
- https://developer.apple.com/sample-code/app-store-connect/app-store-connect-openapi-specification.zip (schema dated 2026-09-23)

| Applicable area | Result |
|---|---|
| Safety (1) / age content | Curated word puzzles; no UGC, chat, gambling, prizes or mature content; 4+ questionnaire saved |
| Performance (2.1) | Processed build valid and exhaustive content tests pass; final signed-device QA remains required |
| Metadata (2.3.1/2.3.2/2.3.5/2.3.6/2.3.7) | Feature and paid-boundary parity, categories and age rating verified; media deferred |
| Business (3.1.1) | Non-consumable StoreKit purchase, localized price, restore flow, accurate unlock; final purchase QA and IAP review screenshot pending |
| Design (4) | Native SwiftUI puzzle app and device layout source reviewed; no new accessibility nutrition claims without device evidence |
| Legal (5.1.1/5.2) | Policy reachable, no-data label published, required-reason manifest present, attribution and content rights recorded; exact signed archive inventory remains a final release check |
| Regional scope | Japan only; no hypothetical worldwide compliance claim; no EU availability added |

## Validation and remaining work

- Existing release regression suite: **6/6 passed**, including exhaustive validation of all shipped puzzles and digest/manifest checks.
- API readback: listing, EULA, categories, age, app/IAP prices, Japan-only territories and IAP localization confirmed.
- No changes to gameplay, purchase implementation or production signing were needed.
- Required media: authentic iPhone/iPad App Store screenshot sets and the IAP App Review screenshot. Preview videos are optional.
- Review contact: name, email and international phone number must be populated. Automatic approval review rejected copying these from the Gym app as outside the Kanji-specific authorization. No alternative source was used to bypass that decision.
- Final release evidence: use the same attached TestFlight build to confirm both device layouts, gameplay, privacy/licence screens and sandbox purchase/restore/refund behavior. Do not publish accessibility claims based only on source.
- After media/contact and final QA, include the first non-consumable and app version in the same App Review submission. Do not submit or publish the app merely because metadata is saved.
