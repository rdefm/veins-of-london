# 117 — Debug "Combat setup" modal still renders amber, not ui_action_red

**What to build:** Discovered during human visual QA (screenshot2-12-09-2026.PNG):
the Phone > Debug "Combat setup" modal (`scenes/components/modal_layer.gd`
`_build_combat_setup()`) renders its three `OptionButton`s (Enemy type,
Number of enemies, Value tier) and its "Fight"/"Cancel" buttons in the
default theme's amber (`theme/main_theme.tres` `Button/styles/normal`,
`#c8871f`-ish), not `ui_action_red` — the only screen left doing this now
that combat's own action cards (`combat.gd`) and the HQ Train button
(`modal_layer.gd`) already made the switch (see those files' own
"...uses_ui_action_red_not_the_default_theme_amber" tests).

Root cause (diagnosed): `_build_combat_setup()` builds every control with
bare `UI.button()`/`UI.option_button()` and never applies a recolour pass —
unlike the Phone app screens, which call `ContactCards.apply_phone_os_chrome()`
once over everything they build (`phone.gd:141`, `contacts.gd`). This modal
was added as a debug-only harness in front of `Combat.start_raid()` and
was never brought into either recolour pass.

**Blocked by:** None.

**Status:** ready-for-agent

- [ ] `_build_combat_setup()`'s three `OptionButton`s and its "Fight"/"Cancel"
      buttons render `ui_action_red`, not the default theme amber — either by
      running `ContactCards.apply_phone_os_chrome()` over `_card_content` once
      the modal is built (same convention `phone.gd`/`contacts.gd` use), or by
      styling them directly if that helper doesn't fit a `ModalLayer`-owned
      dialog.
- [ ] Audit every other `ModalLayer` dialog builder (`_build_*` functions in
      `scenes/components/modal_layer.gd`) for the same bare
      `UI.button()`/`UI.option_button()`-with-no-recolour pattern; fix any
      found (the combat-setup ally-row toggle button at
      `_build_combat_setup_ally_row()` is one likely sibling).
- [ ] `godot --headless -s scripts/check_runner.gd -- path/to/file.gd` clean
      on every touched file; `scripts/run_tests.sh` passes.

Human visual QA note: on-device, open Phone > Debug > Combat > Open and
confirm the dropdowns and Fight/Cancel buttons read `ui_action_red`
(pillar-box red), matching the rest of the app.
