# StoreKit setup

## Production product

Create exactly one In-App Purchase in App Store Connect:

- Type: **Non-Consumable**
- Reference name: **Kanji Crossword Lifetime Unlock**
- Product ID: **com.gooduse.kanjicrossword.pro.lifetime**
- Japan launch price hypothesis: **¥1,000**
- Japanese display name: **全問題を買い切りで解放**
- Japanese description: **全360問を一度の購入ですべて解放**

The app displays the App Store's localized live price; ¥1,000 is configured in
App Store Connect, not embedded into the production UI.

## Local Xcode testing

`Products.storekit` contains the matching non-consumable for local development.
The shared `KanjiCrossword` scheme already points at it; to change it, use:

`Scheme > Edit Scheme > Run > Options > StoreKit Configuration`

Use Xcode's StoreKit transaction manager to exercise:

1. successful non-consumable purchase;
2. user cancellation;
3. interrupted/pending purchase followed by approval;
4. failed purchase;
5. explicit Restore Purchases with and without an existing transaction;
6. refund/revocation and immediate relocking of paid puzzles;
7. launch while offline after a previously verified purchase;
8. launch online after a refunded purchase to prove stale Keychain access is removed;
9. reinstall/new-device restoration through current entitlements.

## Release gate

Do not ship until the App Store Connect product ID exactly matches
`LifetimePurchaseConfiguration.productID`, the Paid Applications agreement is
active, sandbox purchase/restore/refund tests pass, and the IAP is attached to
the submitted app version for review.
