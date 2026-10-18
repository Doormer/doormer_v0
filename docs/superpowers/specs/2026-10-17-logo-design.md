# Doormer Logo Design

## Goal

Replace the placeholder door logo on the website and Flutter's default app
icons with the new Doormer logo, so the brand looks the same everywhere it
appears.

## The logo

The logo shows what Doormer does: a question becomes a path through levels,
and the path leads to a door that opens on the answer. It shows the moment
just before the answer: two levels are done, the third is in progress, and a
mystery card still waits behind the door, as in the app ("Answer unlocks after
step 3").

### Symbol

- **Question path:** a "?" hook drawn as a violet path (`#8E74FF`) with a
  dashed cream centre line (`#FFF4FF`).
- **Levels:** three stops on the path. The first two are finished: gold
  (`#FFD84D`) with a dark tick (`#2B2100`) and a night outline (`#150F2E`).
  The third is the current level: mint (`#00E5A0`) with a cream ring, a dark
  centre (`#062B1E`) and a soft mint glow.
- **Door:** the path ends at the top of an arched door with a cream frame.
  Inside is deep space: a glow from red (`#F0364F`) at the centre through
  crimson (`#A3122E`) to near-black red (`#2A0615`) at the edges.
- **Mystery card:** a face-down purple card (`#7A5CFF`) with a gold edge and a
  gold four-point star stands in the doorway, tilted slightly. A thin gold
  ring circles it like a planet's ring, passing behind the card and in front
  of it, with a cream four-point star travelling on the ring. Two tiny cream
  stars, one bright and one faint, sit in the dark. Nothing inside the door
  crosses its frame. A soft mint glow sits on the floor under the door.
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

App icons use the same artwork at every size. It comes in four shapes:

1. **Rounded tile:** the full icon with transparent corners. Used for the
   web app's standard icons, Android's older launcher icon, Windows (48 px
   and up) and Linux.
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

### Favicon

Browser tabs show icons at 16 px (32 px on sharp screens), where the full
icon's path, levels and door blur together. So browser tabs, and the Windows
title bar and taskbar, use a simpler icon instead: the "d" from the wordmark
in cream (`#FFF4FF`), 22/32 of the tile's height, centred on the same rounded
night tile.

## Where it goes

### Website (`web/site/`)

- A new folder, `web/site/img/brand/`, holds the four master files:
  `doormer-icon.svg` (rounded tile), `doormer-favicon.svg` (the "d" for
  browser tabs), `doormer-wordmark.svg` (for dark backgrounds) and
  `doormer-wordmark-light.svg` (for light backgrounds).
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
- **Browser-tab icon:** every page's `<link rel="icon">` points to the
  favicon, `/site/img/brand/doormer-favicon.svg`. Delete
  `web/site/img/favicon.svg`.
- **`web/site/img/apple-touch-icon.png`:** 180 × 180 px, square shape.
- **`web/site/img/og-image.jpg`** (the image shown when the site is shared):
  1200 × 630 px. Replace the old logo in the top-left corner with the new
  wordmark and leave the rest of the image unchanged.
- **`site.css`:** replace the `.brand__mark` rules (including the narrow-screen
  one) and the `.compare__brand svg` rule with rules that size the wordmark
  image.

### Flutter web app (`web/`)

- `web/favicon.png`: the favicon at 32 × 32 px (currently a 16 × 16 px
  Flutter logo).
- `web/icons/Icon-192.png` and `web/icons/Icon-512.png`: rounded tile.
- `web/icons/Icon-maskable-192.png` and `web/icons/Icon-maskable-512.png`:
  safe-zone version.
- `web/manifest.json`: change `background_color` and `theme_color` from
  Flutter blue (`#0175C2`) to `#08060F`, the colour the site pages already use
  for `theme-color`.
- `web/index.html`: point the iPhone home-screen icon (`apple-touch-icon`) at
  `site/img/apple-touch-icon.png`. It currently uses `Icon-192.png`, whose
  transparent corners iPhones would fill with black.
- `web/index.html` and `web/manifest.json`: call the app "Doormer" (it was
  "doormer") and replace Flutter's "A new Flutter project." description with
  "Snap a homework question and Doormer turns it into a step-by-step quest
  with diagrams, a checked answer and rewards." The website's version ends
  with "Free, in your browser.", which reads oddly once the app is installed.
- **Loading screen:** while the app downloads, the page was blank white for a
  few seconds on a phone network before the dark app appeared. `web/index.html`
  now shows the icon's artwork without its tile
  (`web/icons/doormer-icon-artwork.svg`, 220 × 220 px) in the middle of a CSS
  copy of the app's background (`QuestBackdrop`: the violet glow, the 15 px
  dot grid and the pink top light), so when the app appears only the door
  changes. Flutter draws over it and the page removes it on
  `flutter-first-frame`, so the app still shows if that event never comes.

### Native apps

- **Android:** replace `ic_launcher.png` in
  `android/app/src/main/res/mipmap-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/` (48, 72,
  96, 144 and 192 px, rounded tile). Add an adaptive icon
  (`mipmap-anydpi-v26/ic_launcher.xml`) whose background layer is the night
  gradient (`drawable/ic_launcher_background.xml`) and whose foreground layer
  is the safe-zone artwork (`ic_launcher_foreground.png` in each `mipmap-*`
  folder). Without it, Android 8 and later shrink the icon inside a white
  shape.
- **iPhone and iPad:** replace the 15 PNGs in
  `ios/Runner/Assets.xcassets/AppIcon.appiconset/`, square shape, with no
  transparency (an App Store requirement).
- **Mac:** replace the 7 PNGs (16 to 1024 px) in
  `macos/Runner/Assets.xcassets/AppIcon.appiconset/`, Mac shape.
- **Windows:** replace `windows/runner/resources/app_icon.ico` with one that
  holds the favicon at 16, 24 and 32 px, for the title bar and taskbar, and
  the rounded tile at 48, 64, 128 and 256 px.
- **Linux:** the app has no icon today. Add
  `linux/runner/resources/app_icon.png` (256 × 256 px, rounded tile), install
  it into the bundle's `data` folder, and set it as the window icon when the
  window opens.
- **App name:** Android's label, the Windows window title and version
  details, and the Linux window title say "Doormer" (they said "doormer");
  the iPhone already did. `MaterialApp.title` is "Doormer", which names the
  app in Android's recent apps. Package names, bundle IDs and executable names
  stay as they are.
- **Launch screens:** the app's background colour, `#0F0A26`
  (`QuestPalette.glowBottom`, which fills most of a phone's first screen),
  instead of white: `ios/Runner/Base.lproj/LaunchScreen.storyboard`, and on
  Android `drawable/launch_background.xml`,
  `drawable-v21/launch_background.xml` and the `NormalTheme` window
  background, plus `values-v31/` and `values-night-v31/` styles for Android 12
  and later, which add the app icon in the middle themselves. The iPhone gets
  no logo: Apple's guidelines say "The launch screen isn't a branding
  opportunity".

### Not included

- A logo on the app's own screens, such as sign-up and log-in. In mock-ups it
  cluttered the form, and of 11 apps teenagers use, most keep their logo
  small or leave it out of these forms; several name the app in the heading
  instead.
- The Mac app's name. Its menu bar still says "doormer" because the name
  comes from the Xcode product name, which also names the `doormer.app`
  bundle that the Mac tests load (`TEST_HOST`).
- A version with the symbol next to the plain word, because nothing uses it.

## Making the files

- The four SVGs in `web/site/img/brand/` are the source of truth. Export
  every PNG and ICO from `doormer-icon.svg`, or from `doormer-favicon.svg` for
  the favicon, at its exact pixel size, rather than scaling down another PNG.
- Add `tool/generate_brand_icons.dart`, which regenerates every exported icon
  from the master SVGs with headless Chrome, so a future change to the logo
  takes one command (`dart run tool/generate_brand_icons.dart`). Run it by
  hand; it is not part of the build. It also writes the loading screen's
  `web/icons/doormer-icon-artwork.svg`, the master icon without its tile.
- Make the wordmark SVGs and the favicon once by converting the Fredoka Bold
  letters to outlines, then commit them. They need no script.

## Verification

- `flutter test test/site/site_pages_test.dart` passes. Its existing checks
  cover alt text, links to files that exist and the 70 KB home page limit. The
  wordmark loads as a separate file, so pages get smaller rather than larger.
- Add tests that check:
  - every page's header and footer brand link shows `doormer-wordmark.svg`,
    its browser-tab icon is `doormer-favicon.svg`, and no page still contains
    the old door mark;
  - the wordmark SVGs and the favicon contain no `<text>` elements;
  - `web/manifest.json` uses `#08060F`;
  - the web app is called "Doormer" and describes itself the same way in
    `index.html` and the manifest;
  - the loading screen's door is the master icon without its tile, and its
    background uses the app's `QuestPalette` colours.
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
    <radialGradient id="portal" cx="60" cy="84" r="23" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#F0364F"/><stop offset=".5" stop-color="#A3122E"/><stop offset="1" stop-color="#2A0615"/></radialGradient>
    <clipPath id="icondoorway"><path d="M-17.8 21 V-13 A17.8 17.8 0 0 1 17.8 -13 V21 Z"/></clipPath>
  </defs>
  <rect width="120" height="120" rx="28" fill="url(#night)"/>
  <ellipse cx="60" cy="106" rx="26" ry="3.5" fill="#00E5A0" filter="url(#glow)" opacity=".7"/>
  <path d="M40 106 V72 A20 20 0 0 1 80 72 V106 Z" fill="url(#portal)"/>
  <path d="M40 106 V72 A20 20 0 0 1 80 72 V106" fill="none" stroke="#FFF4FF" stroke-width="4" stroke-linejoin="round"/>
  <g transform="translate(60 84)"><g clip-path="url(#icondoorway)"><g transform="translate(0 2) rotate(-18)"><path d="M-15 0 A15 4.6 0 0 1 15 0" fill="none" stroke="#FFD84D" stroke-opacity=".5" stroke-width="1.2"/></g><circle cx="-12" cy="-16" r=".9" fill="#FFF4FF" opacity=".45"/><circle cx="13" cy="-12" r="1.1" fill="#FFF4FF"/></g><g transform="rotate(-8)"><rect x="-8.5" y="-12" width="17" height="24" rx="2.6" fill="#7A5CFF" stroke="#FFD84D" stroke-width="1.8"/><path d="M0 -5.4 Q0 0 5.4 0 Q0 0 0 5.4 Q0 0 -5.4 0 Q0 0 0 -5.4Z" fill="#FFD84D"/></g><g clip-path="url(#icondoorway)"><g transform="translate(0 2) rotate(-18)"><path d="M15 0 A15 4.6 0 0 1 -15 0" fill="none" stroke="#FFD84D" stroke-width="1.3" stroke-linecap="round"/><path d="M0 -6 Q0 0 6 0 Q0 0 0 6 Q0 0 -6 0 Q0 0 0 -6Z" transform="translate(7.5 3.98) rotate(18) scale(.62)" fill="#FFF4FF"/></g></g></g>
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
to `#150F2E`. The tiny stars, the star on the ring, the path's dashed line and
the current level's ring stay cream.

```svg
<svg xmlns="http://www.w3.org/2000/svg" viewBox="-24 -86 48 89">
  <defs>
    <filter id="glow" x="-60%" y="-60%" width="220%" height="220%"><feGaussianBlur stdDeviation="4"/></filter>
    <radialGradient id="portal" cx="0" cy="-23" r="22" gradientUnits="userSpaceOnUse"><stop offset="0" stop-color="#F0364F"/><stop offset=".5" stop-color="#A3122E"/><stop offset="1" stop-color="#2A0615"/></radialGradient>
    <clipPath id="letterdoorway"><path d="M-18.71 22.58 V-10.75 A18.71 18.71 0 0 1 18.71 -10.75 V22.58 Z"/></clipPath>
  </defs>
  <ellipse cx="0" cy="0" rx="22" ry="2.6" fill="#00E5A0" filter="url(#glow)" opacity=".7"/>
  <path d="M-19.2 0 V-31 A19.2 19.2 0 0 1 19.2 -31 V0 Z" fill="url(#portal)"/>
  <path d="M-19.2 0 V-31 A19.2 19.2 0 0 1 19.2 -31 V0" fill="none" stroke="#FFF4FF" stroke-width="3.6" stroke-linejoin="round"/>
  <g transform="translate(0 -21) scale(.93)"><g clip-path="url(#letterdoorway)"><g transform="translate(0 2) rotate(-18)"><path d="M-15 0 A15 4.6 0 0 1 15 0" fill="none" stroke="#FFD84D" stroke-opacity=".5" stroke-width="1.2"/></g><circle cx="-12" cy="-16" r=".9" fill="#FFF4FF" opacity=".45"/><circle cx="13" cy="-12" r="1.1" fill="#FFF4FF"/></g><g transform="rotate(-8)"><rect x="-8.5" y="-12" width="17" height="24" rx="2.6" fill="#7A5CFF" stroke="#FFD84D" stroke-width="1.8"/><path d="M0 -5.4 Q0 0 5.4 0 Q0 0 0 5.4 Q0 0 -5.4 0 Q0 0 0 -5.4Z" fill="#FFD84D"/></g><g clip-path="url(#letterdoorway)"><g transform="translate(0 2) rotate(-18)"><path d="M15 0 A15 4.6 0 0 1 -15 0" fill="none" stroke="#FFD84D" stroke-width="1.3" stroke-linecap="round"/><path d="M0 -6 Q0 0 6 0 Q0 0 0 6 Q0 0 -6 0 Q0 0 0 -6Z" transform="translate(7.5 3.98) rotate(18) scale(.62)" fill="#FFF4FF"/></g></g></g>
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
