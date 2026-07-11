# RaoBotKit

Shared brand + infrastructure for **RaoBot** games. One source of truth — add this
package to each game and `import RaoBotKit`. Change it once here → every game picks it up.

- Private Swift Package (iOS 17+). Consumed by each game repo via SPM.
- Contains **no game logic** — only reusable brand/identity + UI infra.

## What's inside (all `public`)

| Symbol | What it is |
|---|---|
| `BrandStyle` | RaoBot palette (accent `#2563EB`, ink, amber, green, red) |
| `RaoBotWordmark` / `RaoBotCredit` | the "Rao**Bot**" wordmark and a "by RaoBot" credit |
| `BrandSplash` / `BrandSplashHost` | branded launch splash + a wrapper that auto-dismisses |
| `AppBackground` | soft light/dark gradient backdrop |
| `MarqueeRibbon` | scrolling first-party announcement ribbon (optional `onTap`) |
| `Haptics` | light success/win haptics |
| `Sound` | low-volume SFX via AVAudioPlayer (app supplies `win.wav`) |

## Use it in a game

1. **Add the package:** Xcode → File → **Add Package Dependencies…** → enter the repo
   URL (e.g. `https://github.com/twocommatarget/raobotkit`) → choose a version rule
   (recommended: **Up to Next Major** from the latest tag) → add the **RaoBotKit** library
   to your app target.
   - *Private repo:* Xcode uses your signed-in GitHub account. For **Xcode Cloud**, grant it
     access to this repo in the workflow's repository settings.
2. **Wrap your root** in the splash host:
   ```swift
   import RaoBotKit

   @main struct MyGameApp: App {
       var body: some Scene {
           WindowGroup {
               BrandSplashHost(emoji: "🧩", base: "Tan", accent: "gram") {
                   HomeView()
               }
           }
       }
   }
   ```
3. **Use the brand** anywhere: `.background(AppBackground())`, `RaoBotCredit()`,
   `BrandStyle.accent`/`.amber`, `MarqueeRibbon(messages: [...], onTap: { requestReview() })`.
4. **Sounds:** drop a `win.wav` (and optional `found.wav`) into your app target; `Sound.win()`
   / `Sound.found()` will use them, else fall back to a system sound.

## Versioning

Tag releases (`1.0.0`, `1.1.0`, …). Games pin "Up to Next Major," so improvements flow on
the next build and breaking changes are opt-in. Bump a game's pin to adopt a new version.

## Not included (stays per-game)

Game-specific theming/logic (e.g. a game's `ThemeStyle`, its engine/`*Core` package, content,
icon). Also add per game: `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO`, iPhone-only if
it's an iPhone game, and the `ci_scripts/` (tests + build-number) pattern.
