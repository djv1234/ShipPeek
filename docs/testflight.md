# Shipping a build to TestFlight

## Before the first archive

1. **Team ID.** Put your 10-character Apple Developer Team ID in `project.yml` under
   `DEVELOPMENT_TEAM` (developer.apple.com → Membership details), then `xcodegen generate`.
   It must live in `project.yml`: the `.xcodeproj` is generated and gitignored, so a team picked in
   Xcode's Signing & Capabilities pane disappears on the next regeneration.
2. **App Store Connect record.** appstoreconnect.apple.com → Apps → **+** → New App.
   Bundle ID `com.sergeyvolf.ShipPeek`, SKU anything unique (`shippeek-ios` is fine).
   The **App Name must be unique across the entire App Store** — if "ShipPeek" is taken, pick a
   variant here; it's the store listing name, not the name under the icon (that's
   `CFBundleDisplayName`).
3. **Build number.** Every upload needs a `CURRENT_PROJECT_VERSION` never used before for the
   current `MARKETING_VERSION`. Bump it in `project.yml` and regenerate for each upload.

## Archive and upload

```bash
xcodegen generate && open ShipPeek.xcodeproj
```

In Xcode: destination **Any iOS Device (arm64)** — Archive is disabled while a simulator is
selected — then **Product ▸ Archive**. When Organizer opens: **Distribute App ▸ TestFlight &
App Store ▸ Upload**, and accept the automatic signing prompts.

Processing takes roughly 5–30 minutes. Export compliance is already answered by
`ITSAppUsesNonExemptEncryption: false` in `project.yml`, so no per-upload questionnaire.

## Internal vs external testers

|  | Internal | External |
|---|---|---|
| Who | Up to 100 App Store Connect **users on your team** | Up to 10,000 by email or public link |
| Review | None | Beta App Review on the first build (~24h) |
| Availability | Minutes after processing | After review passes |
| Cost | Testers get account access | None |

Internal is instant but every tester becomes a user on your Apple Developer account. External is
the right call for anyone you would not give account access to.

## Beta App Review notes (external only)

Fill in **Test Information** once, under the TestFlight tab. The reviewer opens the app to an
onboarding screen demanding an Easyship API token and can see nothing without one, so the review
notes **must** include a working sandbox token — otherwise expect a rejection for incomplete
functionality. Something like:

> ShipPeek is a client for the Easyship shipping API. It requires an Easyship API token, entered on
> first launch. Use this sandbox token: `sand_...`. Choose "Sandbox" as the environment. Then open
> the Settings tab and set a ship-from address (Country is required) before requesting a rate in the
> Rates tab.

## What testers do

Install **TestFlight** from the App Store, then open the invite email or public link.

Each tester needs **their own Easyship API token** — the app stores it in the device Keychain and
has no backend, so there is nothing shared to hand out. Testers without an Easyship account can get
no further than onboarding. Give them a sandbox token directly if you want them past that screen.

Builds expire **90 days** after upload.
