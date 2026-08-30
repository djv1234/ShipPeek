# ShipPeek

A SwiftUI iOS app for getting Easyship rate quotes and viewing shipments/tracking. Single-user — your API token is stored in the device Keychain, no backend required.

## Build (on a Mac)

```bash
brew install xcodegen
xcodegen generate
open ShipPeek.xcodeproj
```

Run on an iOS 17+ simulator or device. On first launch you'll be asked for an Easyship API token (Settings > API Access on developers.easyship.com — sandbox tokens start with `sand_`, production with `prod_`) and which environment it belongs to.

Before using the Rate Calculator, set your default ship-from address in the Settings tab — it's used as the origin for every rate request, and **Country is required** (tap the row; it opens a searchable list).

"Get Rates" stays disabled until every requirement is met, and lists what's still missing underneath it. Easyship requires the destination, the parcel's weight *and* all three dimensions, and an HS code (or item category ID) to classify the goods — every one of those was learned from a live 422 rather than the docs, so treat the in-app list as the source of truth.

## App icon

`ShipPeek/Assets.xcassets/AppIcon.appiconset/` is wired for iOS 17 light/dark appearances but has no images yet. Add `AppIcon-Light.png` and `AppIcon-Dark.png` (both 1024×1024; the light one must have no alpha channel) — see [`docs/app-icon.md`](docs/app-icon.md).

## Mockup

[`docs/mockup.html`](docs/mockup.html) is a static, self-contained HTML reference for the UI (open it directly in any browser) — Rates, Shipments, and Settings tabs. Note it predates the customs and required-dimensions fields, so the live Rates screen has more inputs than the mockup shows.

## Structure

- `Networking/` — `EasyshipAPIClient` (async/await URLSession wrapper), `KeychainStore`, environment/base-URL config
- `Models/` — Codable types matching Easyship's `/rates`, `/shipments`, `/shipments/trackings` schemas
- `Features/RateCalculator`, `Features/Shipments`, `Features/Settings` — one View + `@Observable` ViewModel per screen
- `Common/` — shared UI (loading/error states, address form, currency formatting)

The `Easyship*` type names refer to the vendor API this app talks to; the product itself is ShipPeek.
