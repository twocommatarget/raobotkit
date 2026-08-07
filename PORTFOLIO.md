# RaoBot Games — Portfolio State & New-Game Handoff

> Cross-project source of truth for the RaoBot game portfolio. Load this at the start of any
> new conversation to continue without dropping context. Pair with `BRAND.md` (design system)
> in this same repo. Last updated: 2026-08-07.

## At a glance (2026-08-07)
- **LIVE:** GuessWhatWord (v2.1), Wordsy (v1.0).
- **IN REVIEW:** Ghost Wanderer (v1.0), Ghost Deck (v1.0). Both auto-release on approval.
- **IN BUILD:** **Word Heist (v1.0)** — code-complete, simulator-verified, 103 tests green.
  No ASC record yet, nothing uploaded. Next: device test → repo → register bundle ID → record.
- **Outstanding actions:** (1) ~~EU trader status~~ **RESOLVED for now (2026-08-04): EU/EEA
  distribution REMOVED** on all apps (avoids the DSA trader requirement while the account sits on
  the dissolved Iflex entity). UK + US + ~145 other regions stay live. Re-enable EU later via the
  Dubai company (see Who/accounts). (2) **Wordsy v1.1** is CI-green (build 24) but unsubmitted —
  decide ship vs defer. (3) **Ghost Wanderer 1.0.1** audio fix is prepped (build 6) — upload once
  v1.0 clears review. (4) **Ghost Deck 1.0.1** (hand UX + deal cue + audio fix) is code-complete
  on main — upload once its v1.0 clears review. Minor: split Wordsy's Xcode Cloud workflow (Build+Test on main + tag-release).


## Apple account migration (2026-08-04) — READ FIRST

Everything moved off **Iflex Consulting Ltd** (company being wound down) to a personal
**Individual** developer account. **Account IDs, emails, Team IDs, and the ASC API key are
NOT stored here** — this repo is PUBLIC. They live in the gitignored local file
**`ACCOUNT.local.md`** (in this same directory) and in **Bitwarden**.

Non-secret facts:
- Enrolled as **Individual** — the App Store shows the holder's legal name as developer.
- Bundle IDs are now **`ai.raobot.games.*`** — note `games` **PLURAL**; retired Iflex IDs were
  `ai.raobot.game.*` singular.
- Copyright: `2026 Surlu Rao`.
- **EU not distributed** by choice (trader status would publish an individual's address/phone;
  reversible once a company exists).

**Ghost Deck was renamed Curse Deck** — the clean name was available on the new account (plain
"Ghost Deck" had been taken, forcing the old "Ghost Deck: Haunted Card Duel"). Repo and Xcode
project keep the GhostDeck name internally; only the product name changed.

**Apps that were never released cannot be transferred** — Apple requires a released version — so
the two ghost games were recreated from scratch. Wordsy and GuessWhatWord were live, so they used
Apple's proper **app transfer** (preserves users, ratings, rankings).

**✅ MIGRATION COMPLETE (2026-08-07):** all apps now live on the individual account
**HBH7R5DSYD**; Iflex (`Y92A57567J`) is fully retired. **Sign everything with `HBH7R5DSYD`.**
Wordsy's & GuessWhatWord's Xcode projects were updated off the stale `Y92A57567J`. Uploading a
transferred app shows a benign keychain warning (90076: app-id prefix `Y92A57567J.* →
HBH7R5DSYD.*`) — harmless (RaoBot games use UserDefaults, not the Keychain).

### Upload pipeline (no Xcode Cloud, no Apple ID prompt)
`xcodebuild archive` → `xcodebuild -exportArchive` (ExportOptions.plist) → `xcrun altool
--upload-app -f export/X.ipa -t ios --apiKey <KEY_ID> --apiIssuer <ISSUER>` (full command +
the actual key/issuer are in `ACCOUNT.local.md`).
**Gotchas:** (1) signing still needs the Apple ID in Xcode → Settings → Accounts; the API key
uploads but cannot sign. (2) `archive` signs for **development** first (re-signed at export), so
a brand-new team with **zero registered devices** fails with "Your team has no devices" —
register one via `POST /v1/devices`. (3) The ASC API can set metadata/screenshots/age rating
but **cannot create app records** and **cannot set the privacy label** — both are browser-only.

## Who / accounts
- **Brand:** RaoBot (raobot.ai). **Apple:** now a personal **Individual** account (2026-08-04);
  the retired **Iflex Consulting Ltd** org is being wound down. **Team IDs, Apple IDs, and the
  ASC API key are in the gitignored `ACCOUNT.local.md` / Bitwarden — NOT in this public repo.**
  **GitHub:** user `twocommatarget` (gh CLI authenticated). **Support/Marketing URL:** https://raobot.ai
- **✅ Entity status (DONE 2026-08-07):** all apps have migrated off the **now-dissolved Iflex**
  org to the personal **Individual** account, **team `HBH7R5DSYD`** (valid legal person). Sign
  everything with `HBH7R5DSYD`; the old `Y92A57567J` is retired. **Longer-term plan:** set up a
  **Dubai company** → enroll it as an Apple Developer **Org** account → **App Transfer** again →
  complete **DSA Trader Status** → **re-enable EU/EEA**. Until a company exists, **keep EU/EEA
  distribution OFF** (individual trader status would publish a home address/phone). New games:
  publish **without EU/EEA** for now.
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
- `raobotkit` (**PUBLIC**, tag **1.0.1**) — shared package; **`BRAND.md` at its root is the
  design-system brief — read it first for any new game.** (Public so Xcode Cloud can resolve
  it without auth — see the RaoBotKit section below.)
- `wordsy-legal` (PUBLIC) — GitHub Pages privacy policy for ALL games, live at
  https://twocommatarget.github.io/wordsy-legal/ ("RaoBot Games — Privacy Policy")

## Game status
- **Wordsy** (word search): bundle `ai.raobot.game.wordsy`, accent **green**. **v1.0 LIVE.**
  v1.1 (migrated onto the RaoBotKit package) is **CI-green (build 24) but NOT submitted** —
  internal-only change; decide ship (attach build 24 to a 1.1 version + submit, or `git tag v1.1`)
  vs defer into the next feature update.
- **GuessWhatWord** (Taboo-style party game): bundle `com.Iflex.ios.GuessWhat`, App Store id
  **598264247**, accent **amber**. **v2.1 LIVE** (adds in-app rating: Settings link + StoreKit
  requestReview after 2nd/8th game).
- **Ghost Wanderer**: bundle `ai.raobot.game.ghostwanderer`, App Store id **6796990138**,
  repo `ghostwanderer`, directory `Games/GhostWanderer/`. Accent **spectral violet `#8F7BE0`**
  (spec-defined dark look intentionally overrides the RaoBot palette in-game).
  **v1.0 IN REVIEW (2026-08-01, build 5, auto-release on approval).**
  9+ rating, privacy "Data Not Collected" (local-only v1.0: no telemetry/networked
  leaderboard — shared privacy page stays accurate), custom dark splash (not BrandSplash),
  display name "Wanderer". **v1.0.1 PREPPED (2026-08-03, build 6):** audio session fixed
  `.ambient` → `.playback`+`.mixWithOthers` so it's audible on the silent switch (as `.ambient`
  it was muted and read as broken) — builds clean; **upload only after v1.0 clears review.**
  v1.1 backlog: "Haunt a Friend" ghost share, networked leaderboard/telemetry. See the game's
  PROJECT_HANDOFF.md.
- **Ghost Deck** (IN REVIEW): bundle `ai.raobot.game.ghostdeck`, repo `ghostdeck`,
  directory `Games/GhostDeck/`. Accent **wisp teal `#7BD8A8`**. Haunted card duel vs "the
  Deceiver", companion to Ghost Wanderer (same dark identity + synth kit).
  **Core + app COMPLETE, simulator-verified** (2026-08-01): level-1 engine + AI ported from the validated
  prototypes, 15 tests green incl. 1,000-game CI harness (AI 66.4% vs random-legal).
  Decisions: offline v1.0 (vs-AI + pass-and-play, level-1 ruleset only),
  (spec's working title was "Wanderer's Deck"; NEVER use "UNO" anywhere — Mattel mark, not
  even in the keyword field: guideline 2.3.7).
  **Store record complete (2026-08-02, ASC app ID 6797127758): store name
  "Ghost Deck: Haunted Card Duel"** — plain "Ghost Deck" was TAKEN on the App Store;
  device display name stays "Ghost Deck". Games > Card/Strategy, 9+ (mild horror themes),
  Data Not Collected, free in 175 countries, English (U.K.), SKU `ghostdeck`, auto-release.
  Build 1.0 (1) uploaded via **direct CLI archive+upload** (no Xcode Cloud needed):
  `xcodebuild archive` + `-exportArchive` with `method=app-store-connect, destination=upload,
  -allowProvisioningUpdates` — bundle ID must first be REGISTERED MANUALLY at
  developer.apple.com/identifiers (running on device does NOT register it). Attached to
  v1.0 and **SUBMITTED — IN REVIEW (auto-release on approval).**
  **v1.0.1 code-complete on main (2026-08-03, NOT uploaded — ship after v1.0 clears review):**
  newest cards enter the hand on the LEFT (+ auto-scroll), scroll-aware »/« overflow chevrons
  (onScrollGeometryChange on iOS 18+ — GeometryReader-in-content offset tracking is DEAD there),
  hand card count, drawn/hexed-card fly-in, deal-open cue, audio `.playback+.mixWithOthers`.
  v1.1 backlog: level-2 curses, online two-phone mode. See the game's PROJECT_HANDOFF.md.
- **Word Heist** (word-puzzle caper): bundle `ai.raobot.games.wordheist`, repo `wordheist`
  (**not yet created**), directory `Games/WordHeist/`. Accent **vault crimson `#C6455A`**.
  Every vault is locked with language — five lock types (anagram tumbler, synonym laser grid,
  Caesar cipher, word ladder, cryptic clue) behind one `Lock` protocol, so heists are pure data.
  **v1.0 CODE-COMPLETE + SIMULATOR-VERIFIED (2026-08-06), NOT uploaded, no ASC record.**
  103 tests green (82 `WordHeistCore` incl. ContentLint over the shipped campaign, 13 app,
  8 XCUITest covering both full clears, a blown-job regroup, the Daily Job share sheet and
  two tumbler regressions);
  Release archive succeeds. 10-heist campaign (3 rookie / 4 intermediate / 3 mastermind) with
  sequential unlocking, date-seeded **Daily Job** + share grid, crew screen, 4+, privacy
  "Data Not Collected", iPhone-only portrait, encryption-exempt. Rookie tier is pitched at ~11
  (tap tiles, cipher shift stated); mastermind types and deduces. Full RaoBotKit brand shell
  (BrandSplashHost / AppBackground / RaoBotCredit / MarqueeRibbon / Haptics) with the noir
  surfaces layered *over* AppBackground. Content is **generated** by `Scripts/author_content.py`
  — ciphertexts computed, every ladder BFS-proved climbable — and ContentLint is the contract
  the future content pipeline must satisfy. ⚠️ **RaoBotKit's `Telemetry` is deliberately never
  started** so the privacy label stays truthful; starting it would invalidate the label and
  `PrivacyInfo.xcprivacy`. **Two user-reported tumbler bugs fixed 2026-08-07:** lock models
  were not `@Observable`, so tapping a tile mutated the model while the screen stayed frozen
  (a partly filled tumbler reports an empty progress message, so nothing else forced a
  redraw); and typed "nine-pin" mode drew blank slots instead of the scrambled pins, leaving
  7 of 10 heists with nothing to unscramble. Both now have UI regression tests, verified to
  fail without the fix. **Bust rule changed 2026-08-07 (user decision, diverges from the
  prototype):** blowing the job no longer restarts the heist — locks already opened STAY
  open and play resumes at the first lock still shut. The cost moved to `totalAlarms`, which
  keeps counting across regroups, so the perfect-heist bonus is forfeited permanently and the
  saved result records every alarm. Next: device test (VoiceOver, Dynamic Type, cold launch) → repo →
  register bundle ID manually → ASC record. See the game's PROJECT_HANDOFF.md.

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
- **Xcode Cloud workflow Distribution Preparation must be "App Store Connect"**, not
  "TestFlight (Internal Testing Only)" — internal-only builds can NEVER be attached to an
  App Store version (the version page's build picker greys them out with no explanation).
- Xcode Cloud only finds `ci_scripts/` **next to the .xcodeproj** (e.g. `<Game>/ci_scripts/`),
  not at the repo root — check the build log for "Post-Clone script not found".

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
