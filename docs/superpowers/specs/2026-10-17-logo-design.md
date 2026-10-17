# Doormer Logo Design

## Goal

Replace the placeholder door logo on the website and Flutter's default app
icons with the new Doormer logo, so the brand looks the same everywhere it
appears.

## The logo

The logo shows what Doormer does: a question becomes a path through levels,
and the path leads to a door that opens on the answer.

### Symbol

- **Question path:** a "?" hook drawn as a violet path (`#8E74FF`) with a
  dashed cream centre line (`#FFF4FF`).
- **Levels:** three stops on the path. The first two are finished: gold
  (`#FFD84D`) with a dark tick (`#2B2100`) and a night outline (`#150F2E`).
  The third is the current level: mint (`#00E5A0`) with a cream ring, a dark
  centre (`#062B1E`) and a soft mint glow.
- **Portal door:** the path ends at the top of an arched door with a cream
  frame. Inside, a glow runs from cream at the centre through mint and violet
  (`#6C4DFF`) to night at the edges, with two faint cream swirl lines. A gold
  tick in the doorway is the answer. A soft mint glow sits on the floor under
  the door.
- **App icon only:** a rounded-square night background (a gradient from
  `#2E2160` at the top to `#08060F` at the bottom, corner radius 28/120 of the
  width) and three small sparkles in mint, gold and pink (`#FFABF3`).

The exact artwork is under [Reference artwork](#reference-artwork).

### Wordmark

`d[door][door]rmer`: the letters are Fredoka Bold (700), the site's display
font, and both o's are replaced by a letter-sized version of the door.

- The door sits on the baseline and the top of its arch is at 0.52 em, in line
  with the tops of the other lowercase letters (Fredoka's x-height is about
  0.51 em).
- The "?" path rises above the door to about 0.84 em, a little above the top
  of the "d" (0.73 em).
- Each door is 0.48 em wide with 0.02 em of space on each side. The letters
  keep Fredoka's normal spacing.
- The wordmark has no sparkles.

There are two versions:

- **For dark backgrounds** (the website): letters and door frames in cream
  `#FFF4FF`.
- **For light backgrounds:** letters and door frames in night `#150F2E`.

The letters are converted to outlines, so the wordmark looks the same without
the font installed and works when loaded as an image.

### App icon shapes

The same artwork is used at every size, with no simplified small version. It
comes in four shapes:

1. **Rounded tile:** the full icon with transparent corners. Used for the
   website's browser-tab icon, the web app's standard icons, Android's older
   launcher icon, Windows and Linux.
2. **Square:** the night gradient fills the square, with no transparency; the
   device rounds the corners itself. Used for iPhone and iPad and the
   website's home-screen icon.
3. **Safe-zone version:** the artwork (everything except the background)
   scaled to fit inside the central circle that launchers keep when they crop
   an icon. For the web app's maskable icons, the night gradient fills the
   square and the artwork fits the central 80%. For Android's adaptive icon,
   the artwork sits on a transparent foreground layer and fits the central
   66 of 108 dp, and a separate background layer carries the night gradient.
4. **Mac:** the rounded tile takes up 824/1024 of a transparent square canvas
   at every size (824 × 824 px on the 1024 × 1024 px icon), which is Mac's
   standard icon margin.

## Where it goes

### Website (`web/site/`)

- A new folder, `web/site/img/brand/`, holds the three master files:
  `doormer-icon.svg` (rounded tile), `doormer-wordmark.svg` (for dark
  backgrounds) and `doormer-wordmark-light.svg` (for light backgrounds).
- **Header and footer on all nine pages:** replace the inline door SVG
  (`.brand__mark`) and the `doormer` text (`.brand__word`) with
  `<img src="/site/img/brand/doormer-wordmark.svg" alt="">` inside the
  existing brand link. The link keeps `aria-label="Doormer home"`, which is why
  the image's `alt` is empty. Size the image so its letters match today's brand
  text: 1.55 rem, and 1.3 rem on narrow screens.
- **Comparison table on the home page:** the "Doormer" column heading
  (`.compare__brand`) shows the old door mark next to the word. Replace both
  with the wordmark image, with `alt="Doormer"` so the column keeps its name,
  and letters at 1.3 rem.
- **Browser-tab icon:** every page's `<link rel="icon">` points to
  `/site/img/brand/doormer-icon.svg`. Delete `web/site/img/favicon.svg`.
- **`web/site/img/apple-touch-icon.png`:** 180 × 180 px, square shape.
- **`web/site/img/og-image.jpg`** (the image shown when the site is shared):
  1200 × 630 px. Replace the old logo in the top-left corner with the new
  wordmark and leave the rest of the image unchanged.
- **`site.css`:** replace the `.brand__mark` rules (including the narrow-screen
  one) and the `.compare__brand svg` rule with rules that size the wordmark
  image.

### Flutter web app (`web/`)

- `web/favicon.png`: 32 × 32 px rounded tile (currently a 16 × 16 px Flutter
  logo).
- `web/icons/Icon-192.png` and `web/icons/Icon-512.png`: rounded tile.
- `web/icons/Icon-maskable-192.png` and `web/icons/Icon-maskable-512.png`:
  safe-zone version.
- `web/manifest.json`: change `background_color` and `theme_color` from
  Flutter blue (`#0175C2`) to `#08060F`, the colour the site pages already use
  for `theme-color`.

### Native apps

- **Android:** replace `ic_launcher.png` in
  `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/` (48, 72,
  96, 144 and 192 px, rounded tile). Add an adaptive icon
  (`mipmap-anydpi-v26/ic_launcher.xml`) with the night gradient as the
  background layer and the safe-zone artwork as the foreground layer. Without
  it, Android 8 and later shrink the icon inside a white shape.
- **iPhone and iPad:** replace the 15 PNGs in
  `ios/Runner/Assets.xcassets/AppIcon.appiconset/`, square shape, with no
  transparency (an App Store requirement).
- **Mac:** replace the 7 PNGs (16 to 1024 px) in
  `macos/Runner/Assets.xcassets/AppIcon.appiconset/`, Mac shape.
- **Windows:** replace `windows/runner/resources/app_icon.ico` with one that
  holds 16, 24, 32, 48, 64, 128 and 256 px rounded-tile images.
- **Linux:** the app has no icon today. Add a 256 × 256 px rounded-tile PNG to
  the Linux runner, install it with the app bundle and set it as the window
  icon when the window opens.

### Not included

- Launch and splash screens.
- The Flutter app's own screens; none of them show a logo today.
- A version with the symbol next to the plain word, because nothing uses it.

## Making the files

- The three SVGs in `web/site/img/brand/` are the source of truth. Export
  every PNG and ICO from `doormer-icon.svg` at its exact pixel size, rather
  than scaling down another PNG.
- Add a script in `tool/` that regenerates every exported icon from the master
  SVG, so a future change to the logo takes one command. Run it by hand; it is
  not part of the build.
- Make the wordmark SVGs once by converting the Fredoka Bold letters to
  outlines, then commit them. They need no script.

## Verification

- `flutter test test/site/site_pages_test.dart` passes. Its existing checks
  cover alt text, links to files that exist and the 70 KB home page limit. The
  wordmark loads as a separate file, so pages get smaller rather than larger.
- Add tests that check:
  - every page's header and footer brand link shows `doormer-wordmark.svg`,
    and no page still contains the old door mark;
  - the wordmark SVGs contain no `<text>` elements;
  - `web/manifest.json` uses `#08060F`.
- Check every exported icon's pixel size, that the iPhone icons have no
  transparency, and that the Windows ICO holds all seven sizes.
- Look at the home page and one guide page at desktop (1280 px) and phone
  (375 px) widths, and at the browser-tab icon at 16 and 32 px.
- Build and run the Flutter web app and the Mac app to see the new icons, and
  the Android and iPhone apps if their tools are installed. Windows and Linux
  can't be built on a Mac, so check only their icon files.

## Reference artwork

### App icon (rounded tile)

For the square shape, drop `rx` from the background `<rect>`. For the
safe-zone version, scale everything except the background `<rect>` so that
the diagonal of its bounds (x 16–104, y 10–112) fits the launcher's circle.
Place it on a square night background for the web app's maskable icons, or on
a transparent layer for Android's adaptive foreground.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 120 120">
  <defs>
    <linearGradient id="night" x1="0" y1="0" x2="0" y2="120" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#2E2160"/><stop offset="1" stop-color="#08060F"/></linearGradient>
    <filter id="glow" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="4"/></filter>
    <radialGradient id="portal" cx="60" cy="84" r="23" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#FFF4FF"/><stop offset=".25" stop-color="#00E5A0"/><stop offset=".62" stop-color="#6C4DFF"/><stop offset="1" stop-color="#150F2E"/></radialGradient>
  </defs>
  <rect width="120" height="120" rx="28" fill="url(#night)"/>
  <ellipse cx="60" cy="106" rx="26" ry="3.5" fill="#00E5A0" filter="url(#glow)" opacity=".7"/>
  <path d="M40 106 V72 A20 20 0 0 1 80 72 V106 Z" fill="url(#portal)"/>
  <g fill="none" stroke="#FFF4FF" stroke-opacity=".4" stroke-width="1.5" stroke-linecap="round">
    <ellipse cx="60" cy="84" rx="14.5" ry="18" stroke-dasharray="17 11" transform="rotate(18 60 84)"/>
    <ellipse cx="60" cy="84" rx="9.3" ry="11.3" stroke-dasharray="11 7" transform="rotate(-30 60 84)"/>
  </g>
  <path d="M40 106 V72 A20 20 0 0 1 80 72 V106" fill="none" stroke="#FFF4FF" stroke-width="4" stroke-linejoin="round"/>
  <circle cx="60" cy="88" r="6.5" fill="#FFD84D" stroke="#150F2E" stroke-width="2"/>
  <path d="M-3.4 0 l2.5 2.5 l4.6 -4.8" transform="translate(60 88) scale(.9)" fill="none" stroke="#2B2100" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"/>
  <g transform="translate(60 52) scale(.75) translate(-60 -73)">
    <path d="M41 46 A19 19 0 1 1 67 63.5 Q60 67 60 73" fill="none" stroke="#8E74FF" stroke-width="9" stroke-linecap="round"/>
    <path d="M41 46 A19 19 0 1 1 67 63.5 Q60 67 60 73" fill="none" stroke="#FFF4FF" stroke-width="2.5" stroke-dasharray="4 5" stroke-linecap="round"/>
    <circle cx="41" cy="46" r="8.5" fill="#FFD84D" stroke="#150F2E" stroke-width="2"/>
    <path d="M-3.4 0 l2.5 2.5 l4.6 -4.8" transform="translate(41 46)" fill="none" stroke="#2B2100" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"/>
    <circle cx="73.4" cy="32.6" r="8.5" fill="#FFD84D" stroke="#150F2E" stroke-width="2"/>
    <path d="M-3.4 0 l2.5 2.5 l4.6 -4.8" transform="translate(73.4 32.6)" fill="none" stroke="#2B2100" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"/>
    <circle cx="67" cy="63.5" r="12" fill="#00E5A0" filter="url(#glow)" opacity=".8"/>
    <circle cx="67" cy="63.5" r="8.5" fill="#00E5A0" stroke="#FFF4FF" stroke-width="2.5"/>
    <circle cx="67" cy="63.5" r="2.8" fill="#062B1E"/>
  </g>
  <path d="M0 -6 Q0 0 6 0 Q0 0 0 6 Q0 0 -6 0 Q0 0 0 -6Z" transform="translate(24 72) scale(.7)" fill="#00E5A0"/>
  <path d="M0 -6 Q0 0 6 0 Q0 0 0 6 Q0 0 -6 0 Q0 0 0 -6Z" transform="translate(97 40) scale(.8)" fill="#FFD84D"/>
  <path d="M0 -6 Q0 0 6 0 Q0 0 0 6 Q0 0 -6 0 Q0 0 0 -6Z" transform="translate(96 92) scale(.55)" fill="#FFABF3"/>
</svg>
```

### Letter-sized door (wordmark, dark backgrounds)

Units are hundredths of an em, and the baseline is at y = 0. For the
light-background version, change only the door frame's stroke from `#FFF4FF`
to `#150F2E`. The swirl lines, the path's dashed line and the current level's
ring stay cream.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="-24 -86 48 89">
  <defs>
    <filter id="glow" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="4"/></filter>
    <radialGradient id="portal" cx="0" cy="-23" r="22" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#FFF4FF"/><stop offset=".25" stop-color="#00E5A0"/><stop offset=".62" stop-color="#6C4DFF"/><stop offset="1" stop-color="#150F2E"/></radialGradient>
  </defs>
  <ellipse cx="0" cy="0" rx="22" ry="2.6" fill="#00E5A0" filter="url(#glow)" opacity=".7"/>
  <path d="M-19.2 0 V-31 A19.2 19.2 0 0 1 19.2 -31 V0 Z" fill="url(#portal)"/>
  <g fill="none" stroke="#FFF4FF" stroke-opacity=".4" stroke-width="1.3" stroke-linecap="round">
    <ellipse cx="0" cy="-23" rx="14" ry="17" stroke-dasharray="16 10" transform="rotate(18 0 -23)"/>
    <ellipse cx="0" cy="-23" rx="9" ry="11" stroke-dasharray="10 6" transform="rotate(-30 0 -23)"/>
  </g>
  <path d="M-19.2 0 V-31 A19.2 19.2 0 0 1 19.2 -31 V0" fill="none" stroke="#FFF4FF" stroke-width="3.6" stroke-linejoin="round"/>
  <circle cx="0" cy="-17" r="6.6" fill="#FFD84D" stroke="#150F2E" stroke-width="1.8"/>
  <path d="M-3.4 0 l2.5 2.5 l4.6 -4.8" transform="translate(0 -17) scale(.95)" fill="none" stroke="#2B2100" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"/>
  <g transform="translate(0 -52) scale(.62) translate(-60 -73)">
    <path d="M41 46 A19 19 0 1 1 67 63.5 Q60 67 60 73" fill="none" stroke="#8E74FF" stroke-width="9" stroke-linecap="round"/>
    <path d="M41 46 A19 19 0 1 1 67 63.5 Q60 67 60 73" fill="none" stroke="#FFF4FF" stroke-width="2.5" stroke-dasharray="4 5" stroke-linecap="round"/>
    <circle cx="41" cy="46" r="8.5" fill="#FFD84D" stroke="#150F2E" stroke-width="2"/>
    <path d="M-3.4 0 l2.5 2.5 l4.6 -4.8" transform="translate(41 46)" fill="none" stroke="#2B2100" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"/>
    <circle cx="73.4" cy="32.6" r="8.5" fill="#FFD84D" stroke="#150F2E" stroke-width="2"/>
    <path d="M-3.4 0 l2.5 2.5 l4.6 -4.8" transform="translate(73.4 32.6)" fill="none" stroke="#2B2100" stroke-width="2.3" stroke-linecap="round" stroke-linejoin="round"/>
    <circle cx="67" cy="63.5" r="12" fill="#00E5A0" filter="url(#glow)" opacity=".8"/>
    <circle cx="67" cy="63.5" r="8.5" fill="#00E5A0" stroke="#FFF4FF" stroke-width="2.5"/>
    <circle cx="67" cy="63.5" r="2.8" fill="#062B1E"/>
  </g>
</svg>
```
