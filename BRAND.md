# RaoBot — Design System & Shared Kit (RaoBotKit)

**RaoBotKit** is a private shared Swift Package that holds the visual identity and infrastructure
for every RaoBot game, so all games look like siblings and brand changes happen in one place.

Repo: `github.com/twocommatarget/raobotkit` · SPM, iOS 17+ · current tag **1.0.1**.

> **Purpose of this file:** a self-contained brand brief. Paste it into a new game's planning
> conversation (or hand it to a fresh Claude session) and it has everything needed to build a
> game that matches the RaoBot look & feel.

---

## Brand palette (from raobot.ai)

| Token | Hex | Use |
|---|---|---|
| **accent** | `#2563EB` (blue) | primary brand color, links, ribbon background, "Bot" in the wordmark |
| accentLight | `#EFF6FF` | tint backgrounds |
| **ink** | `#0F172A` | primary text / "Rao" in the wordmark |
| **amber** | `#D97706` | secondary accent (GuessWhatWord's game color) |
| **green** | `#16A34A` | success (Wordsy's game color) |
| **red** | `#DC2626` | errors / "don't say" warnings |
| background | `#F8FAFC` | neutral surface |

Each **game picks ONE accent color** for its own screens (Wordsy = green, GuessWhatWord = amber)
while sharing the palette above. The `#2563EB` blue is the *RaoBot house* color (wordmark,
credit, ribbon).

## Typography

- **Wordmarks / titles:** SF Rounded — `.system(size:, weight: .heavy, design: .rounded)`.
- **Body / UI:** system default (SF). Titles are big and friendly; copy is plain and concise.
- **RaoBot wordmark:** "Rao" in ink + "Bot" in accent blue, `.bold` — never an image, always
  this text treatment.

## Look & feel in words

Soft, friendly, kid-safe, uncluttered. Rounded-heavy display type, a gentle diagonal gradient
backdrop, generous spacing, big tappable pill buttons, a light spring animation on entry. No
harsh edges, no dark chrome, no ads. Every game shows a **"by RaoBot"** credit and a brief
branded splash on launch.

---

## Components (all `public`, SwiftUI)

```
BrandStyle                     // enum of the palette colors above + name/websiteURL
RaoBotWordmark(size:onDark:)   // "RaoBot" text logo (ink+accent); onDark flips first half to white
RaoBotCredit()                 // "by RaoBot" line for home screens/footers
AppBackground()                // soft diagonal gradient, light/dark adaptive, ignoresSafeArea
BrandSplash(emoji:base:accent:accentColor:)                          // the launch splash visual
BrandSplashHost(emoji:base:accent:accentColor:duration:) { content } // wraps root; splash then content
MarqueeRibbon(messages:speed:onTap:)                                 // scrolling first-party ribbon (blue), tappable
Haptics.found() / Haptics.win()                                      // light success haptics (kid-friendly, no error buzz)
Sound.found() / Sound.win()                                          // gentle SFX; app supplies win.wav/found.wav, else soft system fallback
```

### Launch splash

`BrandSplash` shows: an emoji line, then a two-tone wordmark (`base` in primary ink + `accent`
in the game's color, SF Rounded heavy 56pt, shrink-to-fit), then the "by RaoBot" credit — over
`AppBackground`, with a spring fade-in. Respects Reduce Motion. `BrandSplashHost` auto-dismisses
after `duration` (default 2.4s); set env var **`RBK_SKIP_SPLASH`** to skip it for screenshots.

### Ribbon

`MarqueeRibbon` is a blue (accent) scrolling strip for **first-party** messages only (tips,
cross-promo, "rate us") — **never third-party ads** (COPPA / Apple kids rules). Driven by
`TimelineView` off wall-clock time (reliable on device; implicit `repeatForever` is not).

---

## App-shell pattern (how every RaoBot game is wired)

```swift
import SwiftUI
import RaoBotKit

@main
struct MyGameApp: App {
    var body: some Scene {
        WindowGroup {
            BrandSplashHost(emoji: "🎲", base: "Game", accent: "Name", accentColor: BrandStyle.amber) {
                MenuView()                    // your home screen
            }
        }
    }
}
```

- **Home screen:** emoji + two-tone wordmark + one-line tagline + big pill **primary button**
  tinted in the game's accent + secondary **Settings** button + `RaoBotCredit()` at the bottom,
  all over `AppBackground()`.
- Use `Haptics` / `Sound` on key events; put a `MarqueeRibbon` at the bottom for a rate-us prompt.

## App icon recipe (keeps icons a family)

Rounded-gradient background in the game's accent color (e.g. Wordsy = indigo→blue,
GuessWhatWord = amber), a **single bold white glyph/motif** representing the game (Wordsy =
magnifier over letter tiles; GuessWhatWord = white speech bubble with "?"), ink-colored details,
soft drop shadow. Simple, readable at home-screen size, no text baked in beyond a short motif.
1024×1024 PNG. (Generate offscreen with AppKit/CoreGraphics if no design tool is handy.)

---

## Adding the package to a new game

1. Xcode → **File → Add Package Dependencies** → `https://github.com/twocommatarget/raobotkit`
   → **Up to Next Major** from `1.0.0` → add the **RaoBotKit** library to the app target.
2. `import RaoBotKit` where you use the symbols.
3. **Commit `Package.resolved`** so Xcode Cloud / clones pin the same version.
4. For **Xcode Cloud + this private package**, grant the workflow **read access to the
   `raobotkit` repo**, or CI can't resolve it.

## Architecture convention (RaoBot games)

Headless **Core SPM package** (pure game logic + content JSON + unit tests, no UI) + thin
**SwiftUI app** (`@Observable` state stores + views) + **RaoBotKit** for brand/infra. Bundle the
content as JSON, validate it with tests, gate CI (Xcode Cloud) on those tests.

## House rules baked into the brand

- **Kid-safe:** no third-party ads, no analytics, no data collection, no accounts, works offline.
- **Privacy:** shared policy for all RaoBot games at
  `https://twocommatarget.github.io/wordsy-legal/` ("RaoBot Games — Privacy Policy"). If a game
  uses the microphone/camera etc., add an on-device-only section and keep the feature opt-in.
- **Bundle IDs:** `ai.raobot.game.<name>` namespace.
- **Support / Marketing URL:** `https://raobot.ai`.
- **Age rating 4+**, but do **not** enroll in the Made-for-Kids category, and do **not** put
  "Kids" in the App Store name/subtitle — Apple rejects that (Guideline 2.3.8) unless you join
  that category. Use "family-friendly" / "ad-free" instead.
- **Signing:** Apple team **Iflex Consulting Ltd** (`Y92A57567J`), Apple ID `smrj@hotmail.com`.

---

## Games using RaoBotKit

| Game | Accent | Bundle ID | Notes |
|---|---|---|---|
| **Wordsy** (word search) | green | `ai.raobot.game.wordsy` | first live game; adopted the package in v1.1 |
| **GuessWhatWord** (Taboo-style) | amber | `com.Iflex.ios.GuessWhat` | rebuild of a legacy app; on the package from day one |
