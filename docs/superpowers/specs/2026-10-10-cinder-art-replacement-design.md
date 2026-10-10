# Cinder Art Replacement Design

## Goal

Replace the six existing Cinder card artworks with the six supplied PNG files
and remove only the superseded Cinder JPEG blobs after the replacements are
verified.

## Scope

Map `Flint.png`, `Wick.png`, and `Rasp.png` from `small/`; `Scorch.png` and
`Kiln.png` from `medium/`; and `The Crucible.png` from `capital/` to the six
matching cards in the `cinder-01` deck. Upload these files to the existing
`card-art` Azure container alongside the current Cinder objects, using the
matching lowercase card names and `.png` extensions.

Update the production deck catalog and fake-backend deck catalog to use the
new PNG URLs. Do not bundle duplicate local copies in the app. Do not change
Meridian art or any non-Cinder blobs.

## Sequence and safety

1. Upload all six PNGs without overwriting or deleting existing objects.
2. Verify each new blob is readable and has the expected image content.
3. Update both deck catalogs to reference the verified PNG URLs.
4. Run targeted checks for the catalogs and card-art behavior.
5. Delete only the six superseded Cinder `.jpg` blobs after successful
   verification and reference updates.

If upload or verification fails, leave the old blobs and catalog references
intact. If Azure access is unavailable, report that blocker rather than
simulating a successful upload or deleting anything.

## Verification

Confirm all six new public URLs return the uploaded PNG images; confirm the
production and fake-backend Cinder deck catalogs reference those URLs; and
confirm only the six old Cinder JPEG blobs are removed. Run the narrowest
relevant API and Flutter tests.
