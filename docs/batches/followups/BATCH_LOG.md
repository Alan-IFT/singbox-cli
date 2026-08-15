# Batch Log — followups

> Append-only. One line per batch event. Written by `/harness-batch`.

- 2026-08-15T03:00Z · pool authored · the `default` pool's nine deliveries left ~40 open rows (R-15 … R-61); grouped by **cause** into 7 tasks per rule 85's "Less is more", not transcribed row-by-row · rows deliberately not built are listed with reasons in `BATCH_PLAN.md` so no future pass re-litigates them
- 2026-08-15T03:00Z · pre-flight · verify_all baseline = PASS 17 / WARN 0 / FAIL 0 / SKIP 1 (measured independently at the close of the `default` batch) · no `.harness/intervention.md` · working tree clean · plan schema valid, no dependency cycles, slugs unique
- 2026-08-15T03:05Z · T-22 · dispatching pm-orchestrator · slug=share-url-userinfo-contract · mode=full · **the class was verified wider than R-42 filed it** before dispatch: `parse_trojan:696` and `parse_hy2:744` share the truncation, and `parse_ss:712-717` already implements the correct split by hand
