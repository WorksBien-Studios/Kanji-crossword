# TestFlight issue ledger

No TestFlight session has run for this app yet.

## Provisioning pending

- Status: `open`
- Stage: `preflight`
- Signature: `ios-source-and-credential-route-missing`
- Resolved: Explicit bundle ID `com.gooduse.kanjicrossword`, App Store Connect app record `6817388023`, internal beta group `Internal QA` (`2825fdbf-298d-4065-8d14-119d600cab79`), and one internal tester are created and mapped.
- Symptom: The default branch does not yet contain a distributable app Xcode project/workspace with a shared scheme, and the App Store Connect API credential route is not configured.
- Prevention: The workflow is fail-closed and performs these checks on Linux before allocating macOS.
- Next action: Add the real iOS app project, fill the Xcode fields in the non-secret app map, configure the App Store Connect credential route, then switch the map state to `ready`.
