# App Store Connect Listing — 漢字ナンクロ 広告なし

Status: **BLOCKED for submission; non-media metadata uploaded**
Prepared: 2026-09-30  
Last native-Japanese / ASO / Apple-compliance audit: 2026-09-30  
Launch storefront: **Japan only**  
Platforms: **iPhone + iPad**  
Minimum OS: **iOS/iPadOS 18.0**  
Business model: **Free download + one non-consumable lifetime unlock**  
StoreKit product ID: `com.gooduse.kanjicrossword.pro.lifetime`

This document is the source of truth for App Store Connect fields that do **not** relate to screenshots, previews, icons, or other media.

The final binary and live legal/support URLs must still be checked against this document before submission. Do not claim a feature in App Store Connect unless the submitted build actually contains it.

---

## 0. Audit findings (2026-09-30)

This draft was audited against (a) native-Japanese phrasing, (b) 2026 App Store ASO/SEO best practice, and (c) current Apple App Review Guidelines and App Store Connect requirements, cross-checked against the actual `runtime`/`ui`/`engine` source. Changes made directly in this document:

- **Native-Japanese fix:** §3 Description had a doubled-particle error ("〜から続きから再開"). Corrected.
- **Subtitle:** describes readability and the kanji crossword format; 25/30 characters. Apple does not publish field-ranking weights or a preferred filled-character count.
- **Keywords:** replaced the difficult-reading/brain-activity filler terms with verified offline-play intent; 95/100 UTF-8 bytes. No private search-volume figures are available.
- **Apple-compliance fix — inaccurate IAP claim:** the IAP Description and IAP review notes stated the lifetime purchase unlocks "記録機能" (history/stats). The `記録` tab in `ui/Sources/KanjiCrosswordUI/KanjiCrosswordRootView.swift` is **not gated** by `purchaseStore.hasLifetimeUnlock` — it is available to every user regardless of purchase state. Claiming the IAP unlocks an already-free feature risks a Guideline 2.3.1 (Accurate Metadata) rejection and a misleading-purchase complaint. Corrected the IAP Description and review notes to only claim what the purchase actually gates (the puzzle set). See §10. If the intent was for history to be a paid feature, that must be fixed in code, not in this document.
- **App Name / Subtitle left deliberately short where it matters:** the Name was **not** expanded to use its full 30-character budget. Apple's Guideline 2.3.7 wants the Name field to be the app's actual name, not a keyword string; the Subtitle is the correct field for extra keyword reach, and that is where the added budget went instead.
- **EULA made explicit:** the product description now includes Apple's Standard EULA URL, while App Store Connect remains configured to use Apple's Standard Licensed Application End User License Agreement. No conflicting custom EULA is used.
- **Category mapping corrected:** App Store Connect uses one Games category plus game subcategories. The intended mapping is Primary Category **Games**, Primary Subcategory **Word**, and Secondary Subcategory **Puzzle**.
- **Website consistency fixed:** the canonical Japanese marketing, support, and privacy pages use the same app name, free boundary, 360-puzzle count, lifetime-purchase model, local-only storage position, and Apple Standard EULA.
- **StoreKit metadata aligned:** the local StoreKit product description now exactly matches the App Store Connect IAP description.

### Open items this document cannot resolve — verify before submission

- **Missing binary requirement, confirmed by source audit — now resolved:** §16 and the §19 checklist require an in-app **プライバシーポリシー** link and a **ライセンス／第三者表記** (JMdict/EDRDG) screen before submission. The privacy-policy link was wired in PR #6 (`af87aaa`). The licence/attribution screen was wired in this update: `LicensesView.swift` (new), reachable from 設定 → プライバシーと法的情報 → ライセンス・第三者表記, citing EDRDG and CC BY-SA 3.0 with links defined once in `PolicyLinks.swift` and locked by a smoke test in `SmokeTests.swift`. Both binary-policy gates in §16/§19 are now met in source; still confirm both screens on the final signed archive before submission.
- **Age rating verified on 2026-09-30:** all questionnaire answers were saved through the current API schema; App Store Connect returns `FOUR_PLUS` (4+).
- **App Tags:** optional discoverability tooling; no unverified rollout claim is made.

---

## 1. New App record

| App Store Connect field | Enter / select |
|---|---|
| Platforms | **iOS** |
| Name | **漢字ナンクロ 広告なし** |
| Primary language | **Japanese** |
| Bundle ID | **com.gooduse.kanjicrossword** |
| SKU | **GOODUSE-KANJI-CROSSWORD-IOS-JP** |
| User Access | **Full Access** unless account administration requires otherwise |

### Name rationale

`漢字ナンクロ` is the direct category phrase and is already used by Japanese customers searching for this format. `広告なし` states the principal product difference without using another developer's brand, an unverifiable superlative, or a price.

Apple limit: 30 characters.  
Current name: 11 characters.

---

## 2. App Information

### Localized name

**漢字ナンクロ 広告なし**

### Subtitle

**大きな文字でじっくり脳トレ・漢字クロスワードパズル**

Apple limit: 30 characters.  
Current subtitle: 25 characters.

The subtitle describes readability and the kanji-crossword puzzle format in 25/30 characters. These phrases are observed in current Japanese App Store listings; no search-volume or ranking-weight estimate is asserted.

### Category and subcategories

- **Primary Category:** Games
- **Primary Subcategory:** Word
- **Secondary Subcategory:** Puzzle

Do not select Education as the primary category. The app is fundamentally a puzzle game; vocabulary review is a secondary benefit.

### Content Rights

Select:

**Yes — this app contains, shows, or accesses third-party content, and I have the necessary rights.**

Reason: the bundled vocabulary/readings are derived from JMdict/EDICT, property of the Electronic Dictionary Research and Development Group (EDRDG), under **CC BY-SA 3.0**. The app does not ship JMdict English glosses or copied commercial dictionary definitions.

Required attribution source in repo:

`engine/data/ATTRIBUTION.md`

Before submission, the final app must expose an easily reachable **Licences / Third-Party Notices** view containing the JMdict/EDRDG attribution and licence reference.

### License Agreement

Select:

**Apple's Standard Licensed Application End User License Agreement**

The public listing description also includes the canonical Standard EULA URL:

`https://www.apple.com/legal/internet-services/itunes/dev/stdeula/`

Do **not** add a custom EULA for v1.

### Made for Kids

Select:

**No**

The app can be suitable for all ages without being enrolled in the Kids category. Do not opt into Made for Kids unless the entire product and future updates are intended to comply permanently with Kids Category rules.

### App Store Server Notifications URL

**Leave blank.**

The product uses StoreKit 2 locally and has no developer-operated commerce server.

### Digital Services Act status

For the current **Japan-only** launch, no EU storefront is enabled. Keep the developer account's existing DSA status accurate; no app-specific EU trader claim is required for this launch.

### Regulated Medical Device

Select:

**No**

The app is a word/puzzle game. Do not make medical, dementia-prevention, diagnosis, treatment, cognitive-health, or therapeutic claims.

---

## 3. Japan Product Page metadata

### Promotional Text

```
広告なし・サブスクなし。大きな文字でじっくり楽しめる漢字ナンクロ。30問を無料で試して、気に入ったら買い切りで全360問を解放。オフラインでも遊べます。
```

Apple limit: 170 characters.  
This copy intentionally states the free boundary and one-time-purchase model without quoting a currency price.

### Description

```
広告に邪魔されず、大きな文字でじっくり解ける漢字ナンクロです。

同じ番号のマスには同じ漢字が入ります。番号を選び、候補の漢字をタップするだけ。漢字ナンクロや漢字クロスワードが好きな方はもちろん、初めての方も自分のペースで楽しめます。

【広告なしで集中】
・広告表示なし
・トラッキングなし
・アカウント登録なし
・通信なしでも遊べるオフライン設計

【全360問・4段階の難易度】
・漢字ナンクロ 240問
・じっくり解ける大盤面 120問
・やさしい／ふつう／むずかしい／達人
・盤面サイズではなく、解き方の難しさに合わせた難易度

【見やすく、操作しやすい】
・大きな文字と広いタップ範囲
・同じ番号のマスをまとめて強調
・ピンチ操作で拡大・縮小
・高コントラスト表示
・iPhone／iPad対応

【途中でやめても安心】
・一手ごとの自動保存
・回数制限のない「元に戻す」「やり直す」
・消去、ヒント、間違い確認
・同じ盤面位置から続きを再開

【完成後もゆっくり確認】
解き終わっても完成盤は勝手に消えません。完成した盤面を確認してから結果へ進めます。
結果では、ヒントや確認の使用回数、修正回数、タイマーを使った場合の所要時間と自己ベスト、完成した熟語と読み方を確認できます。

【30問無料・その後は買い切り】
30問は無料で遊べます。残りの問題は、アプリ内の買い切り購入で解放できます。サブスクリプションやコイン、回数券はありません。
購入済みの場合は「購入を復元」から復元できます。

収録問題は端末内に保存されているため、購入後もオフラインで遊べます。
毎日の頭の体操や暇つぶしに、落ち着いて楽しめる漢字パズルをどうぞ。

アプリの画面と問題は日本語です。購入・購入の復元にはインターネット接続が必要です。記録機能は無料版でも利用できます。

プライバシーポリシー：
https://worksbienstudios.com/apps/kanji-crossword/privacy/

利用規約（Apple標準EULA）：
https://www.apple.com/legal/internet-services/itunes/dev/stdeula/
```

Notes:

- Do **not** add a specific price to the description. App Store pricing is shown separately and may vary by storefront.
- Do **not** state that the app provides word definitions. V1 exposes verified readings only.
- Do **not** claim medical or cognitive-health outcomes.
- The description explicitly discloses that only 30 questions are free and the rest require an in-app purchase, matching App Review Guideline 2.3.2.

### Keywords

Enter exactly:

```
シニア,頭の体操,熟語,語彙,暇つぶし,漢クロ,読み方,初心者,オフライン
```

UTF-8 size: **95 bytes / 100-byte limit**.

ASO rationale:

- Name already covers `漢字`, `ナンクロ`, and `広告なし`.
- Subtitle already covers `大きな文字`, `脳トレ`, `漢字クロスワード`, and `パズル` — so `クロスワード` was removed from this field to avoid wasting bytes on a term the Subtitle now indexes more heavily.
- Categories already cover word/puzzle intent.
- `読み方` and `初心者` match readings and the interactive tutorial; `オフライン` matches bundled offline puzzles. Removed `難読` because the app does not establish a dedicated difficult-reading feature.
- Do not add competitor app names, developer names, trademarks, irrelevant popular terms, or pricing keywords.

### Marketing URL

Target canonical URL:

`https://worksbienstudios.com/apps/kanji-crossword/`

**Submission gate:** URL must be publicly reachable without authentication before entering it in App Store Connect.

If the landing page is not live at submission time, Marketing URL may be left blank because it is optional.

### Support URL

Target canonical URL:

`https://worksbienstudios.com/apps/kanji-crossword/support/`

**Required before submission.**

The page must be publicly reachable and contain real customer-contact information appropriate to applicable law. Do not use a dead route or a generic page that lacks a way to contact support.

### Privacy Policy URL

Canonical URL:

`https://worksbienstudios.com/apps/kanji-crossword/privacy/`

The policy source is published from the production WorksBien website repository, whose `main` branch auto-deploys to `worksbienstudios.com`.

**Final release gate:** confirm this URL returns the published policy without authentication immediately before App Store submission.

The same policy is wired inside the app at:

**設定 → プライバシーと法的情報 → プライバシーポリシー**

### User Privacy Choices URL

**Leave blank.**

The app has no account, advertising, analytics, tracking, remote profile, or developer-held personal data to manage.

### Copyright

```
2026 WorksBien Studios Inc.
```

Apple adds the copyright symbol automatically.

### Version

**1.0**

### What's New in This Version

Not applicable to the first App Store version. Leave absent.

---

## 4. ASO / SEO strategy locked for launch

Current observed Japanese listings repeatedly use search language around:

- 漢字ナンクロ
- クロスワード
- 脳トレ
- シニア
- 頭の体操
- 暇つぶし
- 大人
- 熟語

The metadata deliberately spreads these terms across the metadata fields with minimal unnecessary repetition:

| Indexed surface | Search intent covered |
|---|---|
| Name | 漢字ナンクロ, 広告なし |
| Subtitle | 大きな文字, 脳トレ, 漢字クロスワード, パズル |
| Keywords | シニア, 頭の体操, 熟語, 語彙, 暇つぶし, 漢クロ, 読み方, 初心者, オフライン |
| Primary category | Games relevance |
| Primary subcategory | Word-game relevance |
| Secondary subcategory | Puzzle relevance |
| Description / web search | Natural Japanese descriptions of 漢字ナンクロ, 漢字クロスワード, 熟語, オフライン, 買い切り |

Apple states that App Store search considers text relevance from the title, subtitle, keywords, and primary category, along with user behaviour. The description is also used for web-engine search results after release, so it is written naturally for people first rather than as a keyword block.

---

## 5. App Privacy

### Data collection question

Select:

**No, we do not collect data from this app.**

Then save and publish the App Privacy response.

Rationale for the submitted architecture:

- no account or sign-in;
- no advertising SDK;
- no analytics SDK;
- no attribution SDK;
- no crash-reporting SDK;
- no developer backend;
- no runtime AI service;
- puzzle progress/history/preferences remain local in SwiftData;
- the verified offline purchase snapshot remains on device in Keychain;
- StoreKit communicates with Apple's App Store services rather than a WorksBien server;
- no data is transmitted to WorksBien or a third-party partner and retained off-device.

### Tracking

**No**

Do not request App Tracking Transparency permission.

### Data linked to user

**None**

### Data not linked to user

**None**

### Privacy Choices URL

**None / blank**

### Final privacy-label gate

Before submission, generate Xcode's privacy report from the **exact signed archive** and confirm it still supports the "No data collected" response. If a later SDK or service changes the archive's data collection, update this section and App Store Connect before submission.

---

## 6. Privacy manifest / protected resources

For the final app target:

- App-owned tracking: **false**
- Tracking domains: **none**
- Collected data types: **none**, unless the final archive proves otherwise
- Camera: **not requested**
- Photos library: **not requested**
- Contacts: **not requested**
- Location: **not requested**
- Microphone: **not requested**
- Health: **not requested**
- Bluetooth: **not requested**
- Local Network: **not requested**
- Notifications: local reminders only if implemented; permission is optional and core gameplay must not depend on it

Use Apple's system share sheet / file picker for user-initiated exports instead of broad protected-resource access.

---

## 7. Age Rating questionnaire

Expected result: **4+**.

Answer based on the final v1 content:

### In-App Controls

| Question | Answer |
|---|---|
| Parental Controls | **No** |
| Age Assurance | **No** |

### Capabilities

| Question | Answer |
|---|---|
| Unrestricted Web Access | **No** |
| User-Generated Content | **No** |
| Messaging and Chat | **No** |
| Advertising | **No** |

### Mature / objectionable content

Set frequency to **None** for all applicable descriptors, including:

- profanity or crude humour;
- horror/fear themes;
- mature/suggestive themes;
- sexual content or nudity;
- alcohol, tobacco, or drug references;
- realistic violence;
- cartoon/fantasy violence;
- guns or other weapons;
- medical or wellness content;
- gambling themes.

### Chance-Based Activities

| Question | Answer |
|---|---|
| Contests | **No / None** |
| Gambling | **No / None** |
| Loot boxes / randomized paid items | **No** |

There are no prizes, wagers, random paid rewards, multiplayer, chat, or public user content.

Do not answer age-rating questions by copying this file mechanically if the final binary changes. The submitted answers must reflect the build under review.

---

## 8. Accessibility Nutrition Labels

The current UI architecture was deliberately built with native controls, VoiceOver labels, Dynamic Type, high-contrast behaviour, and non-colour-only selection cues.

Publish only claims that pass final device/simulator QA.

### Intended claims after final QA

- **VoiceOver: Supported**
- **Larger Text: Supported**
- **Differentiate Without Color Alone: Supported**
- **Sufficient Contrast: Supported**
- **Dark Interface: Supported**

### Do not claim until separately verified

- Voice Control
- Reduced Motion
- Captions
- Audio Descriptions

Accessibility labels are factual product claims. If a final audit fails any criterion, leave that claim unselected rather than overstating support.

---

## 9. Pricing and Availability

### App download price

Select:

**Free**

The App Store download itself must remain free. The paid feature is the non-consumable IAP.

### App availability

Launch availability:

**Japan only**

Do not enable other storefronts at v1 unless the UI, metadata, policies, customer support, and content strategy for those storefronts have been reviewed.

### iPhone / iPad

**Available**

### Apple silicon Mac availability

**Disable for v1 unless separately tested and intentionally supported.**

The launch specification is iPhone + iPad.

### Apple Vision Pro compatibility

**Disable for v1 unless separately tested and intentionally supported.**

### Pre-order

**No**

### Version release

Select:

**Automatically release this version after App Review approval**

Use manual release only if there is a specific launch-date dependency.

---

## 10. In-App Purchase — lifetime unlock

Create exactly one IAP.

### General

| Field | Value |
|---|---|
| Type | **Non-Consumable** |
| Reference Name | **Kanji Crossword Lifetime Unlock** |
| Product ID | **com.gooduse.kanjicrossword.pro.lifetime** |

The product ID is immutable after creation. It must exactly match the production StoreKit code.

### Localized Japanese IAP metadata

**Display Name**

```
全問題を買い切りで解放
```

Apple limit: 30 characters.

**Description**

```
全360問を一度の購入ですべて解放
```

Apple limit: 45 characters.

Do not claim the purchase unlocks history/records (記録機能). The 記録 tab is available to every user regardless of purchase state (`ui/Sources/KanjiCrosswordUI/KanjiCrosswordRootView.swift` does not gate it on `purchaseStore.hasLifetimeUnlock`), so describing it as part of the paid unlock would be inaccurate metadata under Guideline 2.3.1.

### Pricing

Japan customer price target:

**¥1,000**

Configure the actual price in App Store Connect. The app itself must continue displaying StoreKit's localized `Product.displayPrice`.

### Availability

**Japan only** for the v1 Japan-only app launch.

### Family Sharing

Select:

**Off / No**

Do not enable Family Sharing for v1 unless entitlement behaviour is explicitly tested and the commercial decision changes.

### Promote on the App Store

**No**

Do not promote the IAP on the App Store product page for v1. This avoids a separate promoted-IAP merchandising surface and its public promotional artwork requirement.

### IAP review notes

```
This is the app's only paid product. It is a non-consumable lifetime unlock.

Product ID:
com.gooduse.kanjicrossword.pro.lifetime

The app is free to download and includes 30 complete puzzles at no charge. The lifetime unlock enables the remaining bundled puzzles for a total of 360 accessible puzzles. Local history/statistics (the 記録 tab) are available to all users regardless of purchase state and are not part of what the IAP unlocks. There is no subscription, consumable currency, advertising, external payment method, account, or server entitlement.

To reach the purchase UI:
1. Open 遊ぶ.
2. Select any puzzle showing a lock icon; or open 設定 and choose 全問題を解放.
3. The purchase sheet displays the localized StoreKit price.
4. 設定 also contains 購入を復元.

The app verifies StoreKit 2 transactions, handles pending/cancelled/failed states, listens for transaction updates, and removes paid access after a verified revocation/refund.

日本語：無料版では30問が遊べます。非消耗型の一度きりの購入で残りの問題が解放され、全360問が利用可能になります。「記録」は無料版でも利用できます。鍵の付いた問題、または「設定」の購入欄から購入画面へ進めます。「設定 → 購入を復元」で復元できます。
```

The IAP App Review screenshot is media and is intentionally outside the scope of this document.

---

## 11. App Review Information

### Sign-in required

Select:

**No**

There is no account and no demo account.

### Review contact

Use the existing valid App Review contact for the developer account/app:

- First name: **[ENTER CURRENT REVIEW CONTACT]**
- Last name: **[ENTER CURRENT REVIEW CONTACT]**
- Email: **[ENTER CURRENT REVIEW CONTACT]**
- Phone: **[ENTER CURRENT REVIEW CONTACT IN INTERNATIONAL +COUNTRYCODE FORMAT]**

Do not invent or use a stale phone number. Apple may contact this person during review.

### App Review Notes

Use:

```
漢字ナンクロ 広告なし is a local-first Japanese kanji number-crossword puzzle game for iPhone and iPad. No sign-in is required.

REVIEW PATH
- The first-launch tutorial is interactive and can be completed immediately.
- Open 遊ぶ to select a puzzle.
- 30 complete puzzles are available free of charge across the two launch modes and four difficulty bands.
- A locked puzzle opens the lifetime-unlock screen.
- The same purchase screen is available from 設定 → 全問題を解放.
- Restore Purchases is available from 設定 → 購入を復元.
- The only IAP is the non-consumable:
  com.gooduse.kanjicrossword.pro.lifetime
- There are no subscriptions, consumable currencies, advertisements, external payment links, accounts, or backend services.

GAMEPLAY
Tap a numbered cell, then tap a kanji tile. All cells with the same number share the same kanji. Undo, redo, erase, hints, mistake checking, pause/resume, autosave, and exact resume are available. Expert puzzles also provide native keyboard entry.

CONTENT
The app bundles 360 validated puzzles locally. Puzzle generation does not occur at runtime. Every shipped puzzle passed the repository's exhaustive uniqueness validator before bundling.

The bundled Japanese vocabulary/readings are derived from JMdict/EDICT, property of EDRDG, used under CC BY-SA 3.0. Only words and readings are exposed in v1; JMdict English glosses and commercial dictionary definitions are not shown. Attribution/licence information is available in the app's Licences / Third-Party Notices screen.

PRIVACY
The app has no advertising, analytics, tracking, account system, developer server, or runtime AI service. Game records and preferences are stored locally. StoreKit is used for the lifetime unlock. The privacy policy is available in-app at 設定 → プライバシーと法的情報 → プライバシーポリシー and at https://worksbienstudios.com/apps/kanji-crossword/privacy/.

No special hardware, account credentials, or external service setup is required to review core gameplay.

日本語の審査手順：
初回の遊び方を終え、「遊ぶ」から問題を選択してください。30問は無料です。鍵の付いた問題、または「設定」の購入欄から「全問題を解放」を開けます。表示価格はStoreKitから取得します。非消耗型の買い切りで全360問が利用可能になります。「記録」は無料版でも利用できます。「設定 → 購入を復元」から購入を復元できます。アカウント、広告、サブスクリプション、外部決済はありません。問題は端末内に収録されています。購入・復元にはネットワーク接続が必要です。設定からプライバシーポリシーと第三者ライセンスにアクセスできます。
```

### Review attachment

No non-media attachment is required.

If App Review needs supporting rights documentation, the repo attribution source is:

`engine/data/ATTRIBUTION.md`

---

## 12. Export Compliance

The app uses Apple system services such as StoreKit and Keychain. It does not implement proprietary/non-standard cryptography.

For the final Xcode app target:

```
ITSAppUsesNonExemptEncryption = NO
```

This selection is appropriate only if the final linked binary uses no non-exempt encryption. Apple's documentation states that encryption limited to Apple operating-system facilities requires no App Store Connect encryption documentation.

Final submission answer:

**Uses non-exempt encryption: No**

If later code introduces a non-Apple or non-exempt cryptographic implementation, reassess this answer before upload.

---

## 13. App Store Server / commerce settings

| Setting | Selection |
|---|---|
| App Store Server Notifications | **Blank / not configured** |
| Subscription group | **None** |
| Introductory offers | **None** |
| Offer codes | **None** |
| Win-back offers | **None** |
| Consumables | **None** |
| External purchase links | **None** |
| Alternative payment | **None** |
| Family Sharing | **Off** |
| Promoted IAP | **Off** |

The Paid Apps Agreement, banking, and tax information must be active in App Store Connect before the non-consumable can be sold.

---

## 14. Game Center and social features

- Game Center: **Off / not used**
- Leaderboards: **None**
- Achievements: **None**
- Multiplayer: **None**
- Chat/messaging: **None**
- User-generated content: **None**
- Sign in with Apple: **Not used**
- Social login: **Not used**

Do not enable unused capabilities in App Store Connect or the final app entitlement set.

---

## 15. Notifications

No notification permission, reminders, or push service are implemented in this release. Do not claim daily reminders or newly delivered daily puzzles.

---

## 16. Legal / third-party notices — mandatory binary checks

Apple requires the privacy policy link both in App Store Connect and inside the app.

Before submission, Settings must expose at least:

1. **プライバシーポリシー** → live privacy URL
2. **ライセンス / 第三者表記** → JMdict/EDRDG CC BY-SA 3.0 attribution

**Status as of 2026-09-29:** both items are now wired. Item 1 (プライバシーポリシー) — `SettingsView.swift` has a `legalSection` ("プライバシーと法的情報") with a native `Link` to the canonical URL, backed by `PolicyLinks.swift` and a smoke test (see `af87aaa`, PR #6). Item 2 (ライセンス / 第三者表記, JMdict/EDRDG attribution) — `LicensesView.swift` is reachable from the same Settings section via `NavigationLink`, cites EDRDG and CC BY-SA 3.0 with links from `PolicyLinks.swift`, and is covered by its own smoke test. Both should still be spot-checked on the final signed build before submission.

Recommended additional links:

3. **サポート**
4. **利用規約** if an app-specific terms page is maintained

The app must not require the user to accept a privacy policy merely to play.

---

## 17. App Tags

Tags are optional discoverability tooling. Review any Apple-generated tags in the offered storefront when available. No unverified rollout or search-ranking claim is made.

---

## 18. Metadata claims that are deliberately prohibited

Do not add any of the following to the listing, keywords, review notes, or IAP metadata unless the product changes and the claim is independently supportable:

- "認知症予防"
- "記憶力が改善する"
- "頭が良くなる"
- medical/therapeutic claims
- "No.1", "best", "official", or other unverifiable superlatives
- competitor names or trademarks
- government/educational endorsement claims
- fake scarcity or sale language
- a hard-coded currency price in the app description
- "完全無料" / "すべて無料"
- unlimited/new daily server content
- word definitions in v1
- native-Japanese editorial sign-off
- online leaderboards, multiplayer, accounts, cloud sync, or AI features

---

## 19. Final non-media submission checklist

### App record

- [ ] iOS selected
- [ ] Primary language = Japanese
- [ ] Name = 漢字ナンクロ 広告なし
- [ ] Bundle ID matches final Xcode target
- [ ] SKU locked
- [ ] Primary category = Games
- [ ] Primary subcategory = Word
- [ ] Secondary subcategory = Puzzle
- [ ] Made for Kids = No
- [ ] Content Rights = Yes, rights secured
- [ ] Standard Apple EULA selected; no custom EULA
- [ ] Apple Standard EULA URL included in the product description
- [ ] Regulated Medical Device = No

### Version metadata

- [ ] Subtitle entered exactly
- [ ] Promotional text entered exactly
- [ ] Description entered exactly
- [ ] Keywords entered exactly and remain <=100 bytes
- [ ] Support URL is live at https://worksbienstudios.com/apps/kanji-crossword/support/
- [ ] Privacy Policy URL returns the published policy on the production site immediately before submission
- [ ] Marketing URL is live at https://worksbienstudios.com/apps/kanji-crossword/
- [ ] Copyright correct
- [ ] Version = 1.0
- [ ] App download price = Free
- [ ] Japan is the only launch storefront
- [ ] automatic release after approval selected

### Privacy

- [ ] "No, we do not collect data from this app"
- [ ] tracking = none
- [ ] ATT not requested
- [ ] exact final archive privacy report reviewed
- [x] privacy policy is wired inside Settings; recheck in the final signed build

### Age rating

- [ ] no parental controls/age assurance
- [ ] no unrestricted web access
- [ ] no UGC/chat
- [ ] no advertising
- [ ] all mature/violent/sexual/drug/medical descriptors = None
- [ ] no contests/gambling/loot boxes
- [ ] resulting rating expected to be 4+

### IAP

- [ ] Non-Consumable selected
- [ ] Product ID matches code exactly
- [ ] Japanese display name set
- [ ] Japanese description set
- [ ] Japan price configured at ¥1,000
- [ ] Japan availability selected
- [ ] Family Sharing off
- [ ] Promoted IAP off
- [ ] IAP review notes entered
- [ ] IAP added to the first app-version submission
- [ ] Paid Apps Agreement active
- [ ] tax/banking setup complete

### App Review

- [ ] Sign-in required = No
- [ ] current review contact entered
- [ ] review notes entered
- [ ] review notes match the exact build
- [ ] no hidden/dormant undocumented features

### Export compliance

- [ ] final binary still uses only exempt/system encryption
- [ ] `ITSAppUsesNonExemptEncryption = NO`
- [ ] no encryption document required

### Binary-policy gates that metadata cannot fix

- [x] Settings contains the canonical in-app Privacy Policy link (`SettingsView.swift` legalSection, verified 2026-09-29); recheck in the final signed build
- [x] Settings contains JMdict/EDRDG licence attribution (`LicensesView.swift`, wired 2026-09-29); recheck in the final signed build
- [x] final 360-puzzle count is verified — confirmed in `content/puzzles-v2.json` (240 kanjiNankuro + 120 kanjiNankuroLarge = 360)
- [ ] 30 free puzzles are accessible without purchase
- [ ] locked puzzles clearly open the IAP
- [ ] StoreKit live price is shown
- [ ] Restore Purchases works
- [ ] refund/revocation removes paid access
- [ ] no ad/analytics/tracking SDK is present
- [ ] no non-disclosed data collection is present
- [ ] final signed archive privacy report reconciled to App Privacy answers

---

## 20. Apple guidance used for this draft

Current Apple guidance reviewed for this package:

- App Store Connect app information and required fields
- Platform version metadata limits
- App privacy responses
- Age rating questionnaire / values
- App Review Guidelines, especially 2.3 Accurate Metadata and 5.1 Privacy
- App Store search and product-page keyword guidance
- In-App Purchase metadata and non-consumable setup
- Restore Purchases guidance
- Export-compliance guidance
- Accessibility Nutrition Labels

Key Apple references:

- https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/
- https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information/
- https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/
- https://developer.apple.com/help/app-store-connect/manage-app-information/set-an-app-age-rating/
- https://developer.apple.com/app-store/review/guidelines/
- https://developer.apple.com/app-store/product-page/
- https://developer.apple.com/app-store/search/
- https://developer.apple.com/help/app-store-connect/reference/in-app-purchases-and-subscriptions/in-app-purchase-information/
- https://developer.apple.com/help/app-store-connect/manage-in-app-purchases/create-consumable-or-non-consumable-in-app-purchases/
- https://developer.apple.com/documentation/storekit/restoring-purchased-products
- https://developer.apple.com/documentation/security/complying-with-encryption-export-regulations
