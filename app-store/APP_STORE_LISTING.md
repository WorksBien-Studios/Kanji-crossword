# App Store Connect Listing — 漢字ナンクロ 広告なし

Status: **submission-ready draft, media excluded**  
Prepared: 2026-09-28  
Launch storefront: **Japan only**  
Platforms: **iPhone + iPad**  
Minimum OS: **iOS/iPadOS 18.0**  
Business model: **Free download + one non-consumable lifetime unlock**  
StoreKit product ID: `com.gooduse.kanjicrossword.pro.lifetime`

This document is the source of truth for App Store Connect fields that do **not** relate to screenshots, previews, icons, or other media.

The final binary and live legal/support URLs must still be checked against this document before submission. Do not claim a feature in App Store Connect unless the submitted build actually contains it.

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

`漢字ナンクロ` is the highest-intent exact category phrase and is already used by Japanese customers searching for this format. `広告なし` states the principal product difference without using another developer's brand, an unverifiable superlative, or a price.

Apple limit: 30 characters.  
Current name: 11 characters.

---

## 2. App Information

### Localized name

**漢字ナンクロ 広告なし**

### Subtitle

**大きな文字でじっくり脳トレ**

Apple limit: 30 characters.  
Current subtitle: 13 characters.

The subtitle covers the senior/readability use case and the high-intent `脳トレ` search phrase without duplicating the app name.

### Primary category

**Games → Word**

### Secondary category

**Games → Puzzle**

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
・次回は同じ盤面位置から続きから再開

【完成後もゆっくり確認】
解き終わっても完成盤は勝手に消えません。完成した盤面を確認してから結果へ進めます。
結果では、ヒントや確認の使用回数、タイマーを使った場合の所要時間、完成した熟語と読み方を確認できます。

【30問無料・その後は買い切り】
最初の30問は無料で遊べます。残りの問題は、アプリ内の買い切り購入で解放できます。サブスクリプションやコイン、回数券はありません。
購入済みの場合は「購入を復元」から復元できます。

収録問題は端末内に保存されているため、購入後もオフラインで遊べます。
毎日の頭の体操や暇つぶしに、落ち着いて楽しめる漢字パズルをどうぞ。
```

Notes:

- Do **not** add a specific price to the description. App Store pricing is shown separately and may vary by storefront.
- Do **not** state that the app provides word definitions. V1 exposes verified readings only.
- Do **not** claim medical or cognitive-health outcomes.
- The description explicitly discloses that only 30 questions are free and the rest require an in-app purchase, matching App Review Guideline 2.3.2.

### Keywords

Enter exactly:

```
シニア,頭の体操,熟語,クロスワード,語彙,暇つぶし,漢クロ,脳活,大人
```

UTF-8 size: **92 bytes / 100-byte limit**.

ASO rationale:

- Name already covers `漢字`, `ナンクロ`, and `広告なし`.
- Subtitle already covers `大きな文字` and `脳トレ`.
- Categories already cover word/puzzle intent.
- Keyword field therefore targets adjacent validated Japanese search language without wasting bytes on exact duplicates.
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

Target canonical URL:

`https://worksbienstudios.com/apps/kanji-crossword/privacy/`

**Required before submission.**

The same privacy policy must also be accessible from inside the final app, for example:

**設定 → プライバシーポリシー**

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

Current high-volume Japanese listings repeatedly use search language around:

- 漢字ナンクロ
- クロスワード
- 脳トレ
- シニア
- 頭の体操
- 暇つぶし
- 大人
- 熟語

The metadata deliberately spreads these terms across the indexed fields instead of repeating them:

| Indexed surface | Search intent covered |
|---|---|
| Name | 漢字ナンクロ, 広告なし |
| Subtitle | 大きな文字, 脳トレ |
| Keywords | シニア, 頭の体操, 熟語, クロスワード, 語彙, 暇つぶし, 漢クロ, 脳活, 大人 |
| Primary category | Word-game relevance |
| Secondary category | Puzzle relevance |
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
全360問と記録機能を一度の購入で解放
```

Apple limit: 45 characters.

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

The app is free to download and includes 30 complete puzzles at no charge. The lifetime unlock enables the remaining bundled puzzles for a total of 360 and keeps access to the app's local history/statistics features. There is no subscription, consumable currency, advertising, external payment method, account, or server entitlement.

To reach the purchase UI:
1. Open 遊ぶ.
2. Select any puzzle showing a lock icon; or open 設定 and choose 全問題を解放.
3. The purchase sheet displays the localized StoreKit price.
4. 設定 also contains 購入を復元.

The app verifies StoreKit 2 transactions, handles pending/cancelled/failed states, listens for transaction updates, and removes paid access after a verified revocation/refund.
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
The app has no advertising, analytics, tracking, account system, developer server, or runtime AI service. Game records and preferences are stored locally. StoreKit is used for the lifetime unlock.

No special hardware, account credentials, or external service setup is required to review core gameplay.
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

If the optional local reminder ships:

- use **local notifications only**;
- no push-notification server;
- notification permission is optional;
- denying notifications must not restrict gameplay;
- wording must not imply that new server-delivered puzzles arrive daily.

The bundled `今日の一問` rotates locally through the finite 360-puzzle library.

If reminders are not present in the final binary, make no notification-related claim in metadata.

---

## 16. Legal / third-party notices — mandatory binary checks

Apple requires the privacy policy link both in App Store Connect and inside the app.

Before submission, Settings must expose at least:

1. **プライバシーポリシー** → live privacy URL
2. **ライセンス / 第三者表記** → JMdict/EDRDG CC BY-SA 3.0 attribution

Recommended additional links:

3. **サポート**
4. **利用規約** if an app-specific terms page is maintained

The app must not require the user to accept a privacy policy merely to play.

---

## 17. App Tags

Apple currently generates/selects tags from metadata and allows developers to deselect irrelevant tags in supported storefronts.

The app is Japan-only at launch, while App Tags are currently surfaced to users in the United States. Therefore:

- do not expand to the U.S. merely for tags;
- if tags appear in App Store Connect, keep only tags that accurately match the actual game;
- deselect any tag implying education certification, medical benefit, multiplayer, gambling, live content, or other unsupported functionality.

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
- [ ] Primary category = Games → Word
- [ ] Secondary category = Games → Puzzle
- [ ] Made for Kids = No
- [ ] Content Rights = Yes, rights secured
- [ ] Standard Apple EULA
- [ ] Regulated Medical Device = No

### Version metadata

- [ ] Subtitle entered exactly
- [ ] Promotional text entered exactly
- [ ] Description entered exactly
- [ ] Keywords entered exactly and remain <=100 bytes
- [ ] Support URL is live
- [ ] Privacy Policy URL is live
- [ ] Marketing URL live or left blank
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
- [ ] privacy policy accessible inside Settings

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

- [ ] Settings contains in-app Privacy Policy link
- [ ] Settings contains JMdict/EDRDG licence attribution
- [ ] final 360-puzzle count is verified
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
