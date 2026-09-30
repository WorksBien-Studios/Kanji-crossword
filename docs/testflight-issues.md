# TestFlight issue ledger

No TestFlight session has run for this app yet.

## Provisioning pending

- Status: `open`
- Stage: `preflight`
- Signature: `credential-route-missing`
- Resolved: Explicit bundle ID `com.gooduse.kanjicrossword`, App Store Connect app record `6817388023`, internal beta group `Internal QA` (`2825fdbf-298d-4065-8d14-119d600cab79`), and one internal tester are created and mapped.
- Symptom: The App Store Connect API credential route is not configured (the app project `app/KanjiCrossword.xcodeproj` and shared scheme `KanjiCrossword` now exist).
- Prevention: The workflow is fail-closed and performs these checks on Linux before allocating macOS.
- Next action: Fill `asc_key_id`/`asc_issuer_id` in the app map, configure the App Store Connect secrets and repository variables, then switch the map state to `ready`.

## Tester target

- Status: `resolved`
- `Internal QA` contains both designated internal tester accounts.
- The delivery helper assigns the exact processed build to that group and attaches the same build to the editable App Store version for later review without re-signing.
