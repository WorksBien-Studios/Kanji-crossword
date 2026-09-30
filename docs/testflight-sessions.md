# TestFlight session history

Append-preserving evidence from every TestFlight GitHub session. Search by repository, workflow, Xcode version, stage, signature, or strategy before starting another run. Record clean successes as carefully as failures.

Confidence meanings: `observed` is one session, `verified` is a successful run proving a specific path or repair, and `generalized` is repeated successful evidence suitable across repositories.

## TS-DD6EB1571B — WorksBien-Studios/Kanji-crossword — partial
<!-- testflight-session-json: {"archive_seconds":0.0,"artifact_downloads":0,"assistant_tool_calls":10,"baseline_run":"","beta_delivery":"failed","commit_sha":"a63333ffd15c1fc0c1743da9dca3b67961290daf","confidence":"observed","credential_alias":"worksbien-org-admin","credential_route":"verified","delivery_seconds":0.0,"dependency_seconds":0.0,"export_seconds":0.0,"failure_signature":"automatic-internal-group-rejects-manual-build-assignment","fallback_reason":"","first_recorded":"2026-09-30T12:48:08+00:00","human_interventions":0,"id":"TS-DD6EB1571B","issue_id":"TF-59472541FF","lane":"full","listing_attachment":"failed","listing_version":"1.0","log_downloads":0,"macos_minutes":3.47,"next_action":"Run the delivery-only repair lane against existing build 1 after merging the automatic-internal-group fix.","notes":"Do not rebuild or re-upload; preserve the accepted build.","outcome":"partial","preflight_seconds":6.0,"processing_outcome":"processed","processing_seconds":98.0,"productivity_minutes_lost":0.0,"queue_seconds":0.0,"recorded_at":"2026-09-30T12:48:33+00:00","release_contract":"established","repo":"WorksBien-Studios/Kanji-crossword","rerun_count":0,"reusable_rule":"","run_url":"https://github.com/WorksBien-Studios/Kanji-crossword/actions/runs/36715323325","session_key":"","stages":"preflight,archive,export,verify,upload,processing,delivery","status_checks":5,"strategy":"Exact-SHA CI; organization-route preflight; one archive; one export; one accepted upload; cheap delivery stage","total_seconds":324.0,"upload_outcome":"accepted","upload_seconds":0.0,"verify_seconds":0.0,"what_worked":"Correct organization key, exact app route, signing, archive, export, verification, upload, and Apple processing all succeeded on the first attempt.","workflow":"Kanji Crossword TestFlight","workflow_dispatches":1,"xcode_version":"26.6"} -->

- Recorded: 2026-09-30T12:48:33+00:00
- Workflow / run: `Kanji Crossword TestFlight` / https://github.com/WorksBien-Studios/Kanji-crossword/actions/runs/36715323325
- Commit / Xcode: `a63333ffd15c1fc0c1743da9dca3b67961290daf` / `26.6`
- Credential route: `worksbien-org-admin` / `verified`
- Lane / baseline: `full` / None
- Release contract / fallback: `established` / None
- Outcome / confidence: `partial` / `observed`
- Upload / processing: `accepted` / `processed`
- Beta delivery / listing attachment: `failed` / `failed`
- Listing version: `1.0`
- Stages reached: preflight,archive,export,verify,upload,processing,delivery
- macOS minutes / total seconds: 3.47 / 324.0
- Phase seconds: queue=0.0, preflight=6.0, dependencies=0.0, archive=0.0, export=0.0, verify=0.0, upload=0.0, processing=98.0, delivery=0.0
- Productivity minutes lost: 0.0
- Human interventions / reruns: 0 / 0
- Assistant calls / status checks / dispatches: 10 / 5 / 1
- Log downloads / artifact downloads: 0 / 0
- Strategy: Exact-SHA CI; organization-route preflight; one archive; one export; one accepted upload; cheap delivery stage
- What worked: Correct organization key, exact app route, signing, archive, export, verification, upload, and Apple processing all succeeded on the first attempt.
- Failure signature / linked issue: automatic-internal-group-rejects-manual-build-assignment / TF-59472541FF
- Reusable rule: Not yet identified
- Next action: Run the delivery-only repair lane against existing build 1 after merging the automatic-internal-group fix.
- Notes: Do not rebuild or re-upload; preserve the accepted build.

