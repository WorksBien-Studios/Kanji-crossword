# TestFlight issue ledger

Record every failed, cancelled, degraded, or unexpectedly expensive TestFlight run. A `fixed` entry must cite a later successful verifying run.

## TF-59472541FF — automatic-internal-group-rejects-manual-build-assignment
<!-- testflight-issue-json: {"first_observed":"2026-09-30T12:48:07+00:00","fix":"Detect isInternalGroup plus hasAccessToAllBuilds, skip the invalid POST, verify automatic group access, then attach and read back the exact existing build.","id":"TF-59472541FF","last_updated":"2026-09-30T13:05:02+00:00","minutes_wasted":0.0,"notes":"","prevention":"Inspect beta-group distribution attributes before choosing automatic or explicit assignment, and verify the exact group/build relationship before success.","productivity_minutes_lost":0.0,"repo":"WorksBien-Studios/Kanji-crossword","root_cause":"The mapped Internal QA group has automatic access to all builds; the helper attempted a manual beta-group relationship POST before listing attachment.","runs":["https://github.com/WorksBien-Studios/Kanji-crossword/actions/runs/36715323325","https://github.com/WorksBien-Studios/Kanji-crossword/actions/runs/36718704996"],"signature":"automatic-internal-group-rejects-manual-build-assignment","stage":"processing","status":"fixed","symptom":"Apple accepted and processed the build, then returned HTTP 422 when the delivery helper manually assigned it to an automatic internal group.","verified_run":"https://github.com/WorksBien-Studios/Kanji-crossword/actions/runs/36718704996","workflow":"Kanji Crossword TestFlight","xcode_version":"26.6"} -->

- Status: `fixed`
- Repository / workflow: `WorksBien-Studios/Kanji-crossword` / `Kanji Crossword TestFlight`
- Xcode / stage: `26.6` / `processing`
- First observed: 2026-09-30T12:48:07+00:00
- Last updated: 2026-09-30T13:05:02+00:00
- Occurrences: 2
- Runner minutes wasted: 0.0
- Productivity minutes lost: 0.0
- Runs:
  - https://github.com/WorksBien-Studios/Kanji-crossword/actions/runs/36715323325
  - https://github.com/WorksBien-Studios/Kanji-crossword/actions/runs/36718704996

**Symptom:** Apple accepted and processed the build, then returned HTTP 422 when the delivery helper manually assigned it to an automatic internal group.

**Root cause:** The mapped Internal QA group has automatic access to all builds; the helper attempted a manual beta-group relationship POST before listing attachment.

**Fix:** Detect isInternalGroup plus hasAccessToAllBuilds, skip the invalid POST, verify automatic group access, then attach and read back the exact existing build.

**Verified by:** https://github.com/WorksBien-Studios/Kanji-crossword/actions/runs/36718704996

**Prevention:** Inspect beta-group distribution attributes before choosing automatic or explicit assignment, and verify the exact group/build relationship before success.

**Notes:** None
