# App icon

Drop the two 1024×1024 PNGs into this folder with exactly these names:

- `AppIcon-Light.png` — the light-appearance icon. **Must be fully opaque (no alpha channel).**
  App Store Connect rejects uploads whose marketing icon has transparency.
- `AppIcon-Dark.png` — the dark-appearance icon. May have transparency; iOS composites it over
  the system dark background.

That's all — `Contents.json` already references both filenames, so Xcode picks them up on the next
build with no further wiring. iOS generates every smaller size (home screen, Settings, Spotlight,
notifications) from the 1024×1024 source; the separate per-size icon files older projects used are
no longer needed.

The third slot in `Contents.json` is the iOS 18 "tinted" appearance, deliberately left without a
filename. iOS derives a monochrome version automatically; add `AppIcon-Tinted.png` (grayscale, on a
transparent background) and a `"filename"` key to that entry only if the automatic one looks wrong.

To check for an alpha channel before committing:

```bash
sips -g hasAlpha AppIcon-Light.png
# strip it if the answer is yes:
sips -s format png -s formatOptions default --setProperty hasAlpha false AppIcon-Light.png
```
