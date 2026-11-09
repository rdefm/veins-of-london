# 07 — Copy trim and cleanup

**What to build:** One vocabulary across the Production tab: Make to, Keep, Sell above. The old "Production:" label, "crafting to" wording and the text line listing keep / sell above / contract need / crafting to are gone, since the bar legend shows the values. A short "Contracts hold N" chip shows only when the contract floor is above the Sell-above cutoff. Projection lines on cards and the Defaults chip are one short sentence. Status chip, group header and projection strings are constants alongside the existing text constants. Dead constants, functions and components left by tickets 01–06 are deleted, and CODEMAP rows for touched files are accurate and under the length cap.

New prose (chips, headings, projection wording): draft against the content guide and flag `PROSE-REVIEW:` in the report.

**Blocked by:** 02, 03, 04, 05, 06.

**Relevant files:** `scenes/phone_apps/bizbrief_app.gd` (`_target_text`, `_auto_sell_text`, `_show_contract_hold`, text constants near top); `scenes/phone_apps/stock_bar.gd`; `scenes/phone_apps/setting_slider.gd`; `docs/CONTENT-GUIDE.md`; `scripts/lint_tokens.sh`; `tests/test_phone_bizbrief.gd`; `CODEMAP.md`.

**Status:** ready-for-agent

- [ ] No "Production:" or "crafting to" strings remain; Defaults and cards use the same verbs.
- [ ] "Contracts hold N" appears only when the floor exceeds the cutoff.
- [ ] No unused constants, functions or components remain; `scripts/check_all.sh` and `scripts/lint_tokens.sh` clean.
- [ ] Tests updated and passing; `PROSE-REVIEW:` flagged.
