# RaoBot Games — Portfolio State & New-Game Handoff

> Cross-project source of truth for the RaoBot game portfolio. Load this at the start of any
> new conversation to continue without dropping context. Pair with `BRAND.md` (design system)
> in this same repo. Last updated: 2026-07-31.

## Who / accounts
- **Brand:** RaoBot (raobot.ai). **Apple:** Iflex Consulting Ltd (Organization), team ID
  `Y92A57567J`, Apple ID `smrj@hotmail.com`. **GitHub:** user `twocommatarget` (gh CLI is
  authenticated in the dev environment). **Support/Marketing URL:** https://raobot.ai
- **Dev machine:** macOS, Xcode 26.6 (iOS 26.5 SDK), Swift 6.3. All apps target **iOS 17**,
  **iPhone-only**, **encryption-exempt**, free, no ads / no data collection.

## Directory layout
```
/Users/surlurao/MyClaudeOutput/
├─ Games/
│  ├─ WordSearch/      → "Wordsy" game (repo: wordsearch)
│  └─ GuessWhatWord/   → GuessWhatWord game (repo: guesswhatword)
└─ RaoBotKit/          → shared brand/infra Swift package (repo: raobotkit) — this file lives here
```

## Repos (GitHub, org twocommatarget)
- `wordsearch` (private) — Wordsy
- `guesswhatword` (private) — GuessWhatWord
- `raobotkit` (private, tag **1.0.1**) — shared package; **`BRAND.md` at its root is the
  design-system brief — read it first for any new game.**
- `wordsy-legal` (PUBLIC) — GitHub Pages privacy policy for ALL games, live at
  https://twocommatarget.github.io/wordsy-legal/ ("RaoBot Games — Privacy Policy")

## Game status
- **Wordsy** (word search): bundle `ai.raobot.game.wordsy`, accent **green**.
  v1.0 **APPROVED & live** (2026-07-30). v1.1 (migrated onto the RaoBotKit package) is
  **built + committed but NOT yet tagged/submitted**. To ship v1.1: grant Xcode Cloud read
  access to the `raobotkit` repo, then `git tag v1.1 && git push origin v1.1`. Also pending:
  set EU trader status in App Store Connect → Business.
- **GuessWhatWord** (Taboo-style party game): bundle `com.Iflex.ios.GuessWhat`, App Store id
  **598264247**, accent **amber**. v2.0 approved & live. v2.1 (adds in-app rating: Settings
  link + StoreKit requestReview after 2nd/8th game) **submitted — Waiting for Review**.
- **Ghost Wanderer** (NEXT — planning): bundle `ai.raobot.game.ghostwanderer`, repo
  `ghostwanderer`, directory `Games/GhostWanderer/`. Accent TBD (not green/amber). Not started
  — spec pending. The `.xcodeproj` shell will be created in Xcode by the user (Option B).

## RaoBotKit (the shared package)
- SPM, iOS 17+, tag 1.0.1. Add via SPM URL `https://github.com/twocommatarget/raobotkit`,
  "Up to Next Major" from 1.0.0. **Commit Package.resolved.**
- **`raobotkit` is a PUBLIC repo (since 2026-08-01)** so Xcode Cloud (and any clone) can
  resolve it with **zero authentication**. This is the fix for the CI clone failure: granting
  the Xcode Cloud GitHub App access to a *private* dependency repo is NOT enough — Xcode Cloud
  clones a private SPM dependency unauthenticated unless it's registered as an additional repo.
  Making the shared kit public sidesteps that entirely for every RaoBot game. The kit holds only
  brand/infra code (palette, splash, ribbon, haptics, sound) — no secrets. Game repos stay private.
- Public API: `BrandStyle` (palette), `RaoBotWordmark`, `RaoBotCredit`, `AppBackground`,
  `BrandSplash`, `BrandSplashHost` (splash-skip env var `RBK_SKIP_SPLASH`), `MarqueeRibbon`,
  `Haptics.found()/win()`, `Sound.found()/win()`.
- Palette: accent `#2563EB` (house blue), ink `#0F172A`, amber `#D97706`, green `#16A34A`,
  red `#DC2626`, bg `#F8FAFC`. Each game picks ONE accent (green/amber taken).

## Architecture convention (every RaoBot game)
Headless **`<Game>Core` SPM package** (pure logic + `content.json` + XCTest, no UI) + thin
**SwiftUI app** (`@Observable` state stores + Views) + **RaoBotKit** for brand/infra. Bundle
content as JSON, validate with tests, gate CI on those tests.
- App shell: `BrandSplashHost(emoji:base:accent:accentColor:) { MenuView() }` → Menu → Game →
  Settings, over `AppBackground()`, with `RaoBotCredit()` + a rate-us `MarqueeRibbon`.
- CI: Xcode Cloud, `ci_scripts/ci_post_clone.sh` runs `swift test` (gates deploys);
  `ci_pre_xcodebuild.sh` sets build number from `$CI_BUILD_NUMBER`.

## App Store rules learned (IMPORTANT)
- **Do NOT put "Kids" in the app name/subtitle** unless you enroll in Made-for-Kids —
  Apple rejects it (Guideline 2.3.8). Use "family-friendly"/"ad-free". Rate **4+**, do NOT
  join Made-for-Kids (its bands cap at 11; we target older too).
- Bundle IDs: `ai.raobot.game.<name>`. Privacy URL = the shared wordsy-legal page. If a game
  uses mic/camera: on-device only, opt-in, add a section to the privacy page + review notes.
- Screenshots: provide **6.5" (1284×2778)** and **6.9" (1320×2868)**. Some older app records
  key to the 6.5" slot specifically.
- **Build number must strictly increase** on every upload.

## Gotchas
- Xcode 26 template defaults deployment target to **26.5** → set to **17.0**.
- Stale incremental CLI builds → use `xcodebuild clean build`.
- `clean build -sdk iphonesimulator` can fail SPM resolution on first pass → run
  `xcodebuild build` again.
- Capture screenshots ~2–4s after launch (avoid splash/transition frames).
- This project style uses Xcode "synchronized folders" — deleting a .swift file auto-removes
  it from the build (no pbxproj edit needed); adding a remote SPM package DOES need pbxproj
  edits (model them on guesswhatword's working entries).
- Commit `Package.resolved` for remote deps (un-ignore it if the template ignores it).

## Per-game docs to read
- Each game has `PROJECT_HANDOFF.md` (standardized 12-section source of truth) + `README.md`.
  Wordsy also has `HANDOFF.md` (detailed living log) and `DESIGN.md` (historical blueprint).

## Starting the NEW game
1. **Decisions needed:** game **name** + wordmark split (e.g. "Word"+"sy"), **accent color**
   (not green/amber), **new app or rebuild** + bundle ID (`ai.raobot.game.<name>`), and the **spec**.
2. **Claude does automatically:** create the directory, `gh repo create <name> --private`, the
   Core package + content + tests, ci_scripts, .gitignore, README, PROJECT_HANDOFF.md, all
   SwiftUI code, icon, pbxproj settings + package wiring, commits/pushes.
3. **Only manual choice — the `.xcodeproj`:** EITHER (A) install XcodeGen so Claude generates
   the whole project from a git-tracked `project.yml` (fully automated), OR (B) do
   File → New → iOS App in Xcode once (~20s), matching the existing two games.
4. **Build order:** repo+dirs → Core package + passing tests → Xcode app shell → add RaoBotKit +
   Core → set iOS17/iPhone-only/encryption-exempt/bundleID → Menu/Game/Settings → icon/sounds →
   CI → screenshots + metadata → submit. Write `PROJECT_HANDOFF.md` from day one.
