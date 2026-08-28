# EasyshipDash

SwiftUI iOS app (iOS 17+) wrapping the Easyship shipping API: rate shopping and a shipments/tracking dashboard. Single-user — API token lives in Keychain, no backend.

## Build

This repo is normally edited on Windows (no Xcode). Building/running requires a Mac:

```bash
brew install xcodegen
xcodegen generate
open EasyshipDash.xcodeproj
```

`project.yml` is the source of truth for the Xcode project (targets, deployment target, bundle id) — never hand-edit a generated `.xcodeproj`.

## Structure

- `Networking/` — `EasyshipAPIClient` (async/await URLSession wrapper), `KeychainStore`, `EasyshipEnvironment` (sandbox/production base URLs)
- `Models/` — Codable types for `/rates`, `/shipments`, `/shipments/trackings`
- `Features/{RateCalculator,Shipments,Settings}/` — one View + `@Observable` ViewModel per screen
- `Common/` — shared UI (loading/error states, address form)

## Easyship API — confirmed facts

The API reference at developers.easyship.com renders its request/response schemas via JavaScript, so `WebFetch`/static scraping only sees partial content and has produced wrong/incomplete answers more than once in this project. Prefer a real request/response sample (Postman, the site's own "Try it" code generator, or an actual API call) over re-fetching those docs.

- Base URL: `https://public-api.easyship.com/2024-09` (production) / `https://public-api-sandbox.easyship.com/2024-09` (sandbox)
- Auth: `Authorization: Bearer {token}` — sandbox tokens prefixed `sand_`, production `prod_`
- `POST /rates` — confirmed working request shape (from Easyship's own generated Swift sample):
  ```
  {
    "origin_address": { line_1, line_2, state, city, postal_code, country_alpha2, contact_name, company_name, contact_phone, contact_email },
    "destination_address": { ...same shape... },
    "parcels": [{
      "total_actual_weight": <number>,
      "box": null,                          // parcel-level box is usually left null
      "items": [{
        "description", "category", "sku", "origin_country_alpha2", "quantity",
        "dimensions": { "length", "width", "height" },   // dimensions live on the ITEM, not the parcel
        "actual_weight", "declared_currency", "declared_customs_value"
      }]
    }],
    "incoterms": "DDU",
    "insurance": { "is_insured": false },
    "courier_settings": { "show_courier_logo_url": false, "apply_shipping_rules": true },
    "shipping_settings": { "units": { "weight": "kg"|"lb", "dimensions": "cm"|"in" } },
    "calculate_tax_and_duties": true
  }
  ```
  - `shipping_settings.units` lets you send lb/in directly — no need to convert to kg/cm client-side. The app sends `{weight: "lb", dimensions: "in"}` since the UI collects US units.
  - `items[].category` is present in every working sample seen so far (e.g. `"fashion"`) but it's unconfirmed whether it's strictly required or what the valid enum values are. `ParcelItem.category` is `String?` and stays nil, so the key is **omitted** rather than sent empty — omitting is likelier to pass validation than an empty string against an enum. If rate requests 4xx, check this field first.
  - Response: `rates[]` with `courier_service`, `total_charge`, `currency`, `min_delivery_time`/`max_delivery_time`, `incoterms`.
  - **Request keys are spelled out explicitly** in each `Encodable`'s `CodingKeys`; the encoder deliberately has no `keyEncodingStrategy`. `.convertToSnakeCase` only breaks on case boundaries, so `line1` stays `line1` where Easyship wants `line_1` — the street lines were silently dropped before this was fixed. The *decoder* still uses `.convertFromSnakeCase`, which is fine for every response type.
- `GET /shipments` — paginated (`page`, `per_page`), filterable (`shipment_state`, `label_state`, dates, country). Response: `{ shipments: [...], meta: { pagination: { page, next, count } } }`. `next` is the next page number or `null` — there's no `total_pages` field, so pagination must follow the cursor, not compute total pages.
- `GET /shipments/trackings` — despite the name, this is the tracking-lookup endpoint (not a sub-resource of `/shipments/{id}`). Filter with `easyship_shipment_id[]=<id>` and `include_checkpoints=true`. Response wrapper is also keyed `shipments` (confusingly, same key as the shipments-list endpoint) — each entry has `status`, `eta_date`, `checkpoints[]`, `tracking_page_url`.
- **Dates aren't one format.** `eta_date` is a bare `yyyy-MM-dd` while timestamps carry fractional seconds, and `JSONDecoder`'s built-in `.iso8601` accepts only the latter — one unparseable date fails the *whole* response, so a single `eta_date` used to take down the tracking screen. All decoding goes through `APIDateDecoding.strategy`, which tries several formats plus epoch seconds. Add to that list rather than reaching for `.iso8601`.
- **Error payload shapes vary** by endpoint (`{"error": {"message": …}}`, `{"errors": […]}`, bare `{"message": …}`). `EasyshipErrorParsing` walks whatever came back for the first human-readable string and falls back to the raw body, so a 422 says what Easyship actually objected to.

## UI simplifications

- Destination entry in Rate Calculator: `Address.isValidForRateRequest` requires country always, postal code only when country is US (other countries either lack postal codes or don't need one for a rate estimate — matches Easyship's own web quote tool, whose "Ship To" step is just a country dropdown + Zip Code field). Country picked from a searchable list (`Common/CountryPicker.swift`, built on `Locale.Region.isoRegions` — no external data file). `RateCalculatorViewModel.lookupCityStateIfNeeded()` uses `CLGeocoder` (on-device, no API key, works for any country) to best-effort fill in city/state for display, but it's cosmetic — the request still goes out with just country + postal if the lookup fails or is skipped. A "Add full address details" button reveals contact name/company/address lines/city/state for when you have them.
- Ship-from address only needs to be entered once, in Settings — every rate request reuses it via `DefaultShipFromStore`.
- Parcel dimensions are behind an "Add dimensions" button (optional — only weight is required).
- `ParcelItem.description` and `.category` are not user-facing — description is hardcoded to `"Item"`, category stays nil and is omitted from the payload. Not shown in the Rate Calculator UI since they don't affect the quote the user cares about; revisit if Easyship's API rejects a missing category (see below). Insurance is likewise not exposed — `RatesRequest.insurance.isInsured` stays at its `false` default.
- The Rate Calculator can't submit without a ship-from address (`RateCalculatorViewModel.hasShipFromAddress` gates `canSubmit`, and the form shows a pointer to Settings). Without it the origin would go out empty and Easyship would 4xx with nothing explaining why.

## Known gaps / follow-ups

- `ParcelItem.category` — valid values unconfirmed; currently omitted from the request. If rate requests start 4xx-ing, check this field first, since the one working sample seen had it populated (`"fashion"`).
- Nothing here has been run against the live API yet, and the repo has no tests. The `/rates` payload is assembled from the sample in this file rather than from a request that's known to have succeeded.
- Easyship's own web quote tool also has a "Residential Address" toggle (Yes/No) on the destination, which affects courier rates (residential surcharges). Haven't confirmed the corresponding `/rates` request field name, so it's not implemented yet.
- No app icon / `Assets.xcassets` set up yet.
- `incoterms`, `courier_settings`, `calculate_tax_and_duties`, `insurance` are hardcoded to sensible defaults in `RatesRequest` rather than user-configurable.
