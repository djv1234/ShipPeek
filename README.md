# ShipPeek

A SwiftUI iOS app for getting Easyship rate quotes and viewing shipments/tracking. Single-user — your API token is stored in the device Keychain, no backend required.

## Build (on a Mac)

```bash
brew install xcodegen
xcodegen generate
open EasyshipDash.xcodeproj
```

Run on an iOS 17+ simulator or device. On first launch you'll be asked for an Easyship API token (Settings > API Access on developers.easyship.com — sandbox tokens start with `sand_`, production with `prod_`) and which environment it belongs to.

Before using the Rate Calculator, set your default ship-from address in the Settings tab — it's used as the origin for every rate request.

## Mockup

[`docs/mockup.html`](docs/mockup.html) is a static, self-contained HTML reference for the UI (open it directly in any browser) — Rates, Shipments, and Settings tabs with the current field simplifications (country + optional postal code, dimensions/full-address behind expand buttons, USD-only value).

## Structure

- `Networking/` — `EasyshipAPIClient` (async/await URLSession wrapper), `KeychainStore`, environment/base-URL config
- `Models/` — Codable types matching Easyship's `/rates`, `/shipments`, `/shipments/trackings` schemas
- `Features/RateCalculator`, `Features/Shipments`, `Features/Settings` — one View + `@Observable` ViewModel per screen
- `Common/` — shared UI (loading/error states, address form, currency formatting)
