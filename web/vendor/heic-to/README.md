# heic-to 1.6.5

`heic-to.js` is `dist/heic-to.js` from the npm package `heic-to@1.6.5`
(https://github.com/hoppergee/heic-to), copied unchanged. It bundles libheif
and is licensed LGPL-3.0; see `LICENSE`.

The app loads it only when the browser cannot decode a HEIC photo itself
(see `lib/src/features/questions/utils/photo/photo_preparer_web.dart`).

To update: `npm pack heic-to@<version>`, then replace `heic-to.js` and
`LICENSE` with the package's `dist/heic-to.js` and `LICENSE`.
