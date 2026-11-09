# Plengo redesign v2 — handoff for Claude Code

1. Copy this whole folder into your Flutter repo as `docs/redesign/` (so you have `docs/redesign/CLAUDE_CODE_PROMPT.md`, `docs/redesign/screens/...`).
2. Open Claude Code in the repo root and paste the kickoff message (see below).
3. Review after Phase 1, Phase 2 and the first redesigned screen before letting it continue.

**Kickoff message:**

> Read `docs/redesign/CLAUDE_CODE_PROMPT.md` and follow it exactly. Also read `docs/redesign/DESIGN_SPEC.md`, `docs/redesign/tokens.json`, `docs/redesign/plengo_tokens.dart` and `docs/redesign/screens/INDEX.md`, and open the screen HTML files as you need them. Start with Phase 0: explore the repo and report back. Don't change any code until I approve.

Live clickable design (the source of truth if the HTML and this spec ever disagree):
https://claude.ai/artifact/NxYuo9qvVHPdzmfXwQQpa9

Contents:
- `CLAUDE_CODE_PROMPT.md`: the full implementation brief (rules, phases, flags, open decisions)
- `DESIGN_SPEC.md`: tokens, components, every screen, offline-download states, motion, feature checklist
- `tokens.json` / `plengo_tokens.dart`: design tokens
- `screens/*.dc.html` + `screens/INDEX.md`: the 36 designed screens and the Dart file each one maps to

The logo and the Montserrat Arabic font are already in the app (`assets/brand/`, `assets/fonts/`); nothing to add.
