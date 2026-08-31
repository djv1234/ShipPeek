# Shipping a build to TestFlight

## Before the first archive

1. **Team ID.** Put your 10-character Apple Developer Team ID in `project.yml` under
   `DEVELOPMENT_TEAM` (developer.apple.com → Membership details), then `xcodegen generate`.
   It must live in `project.yml`: the `.xcodeproj` is generated and gitignored, so a team picked in
   Xcode's Signing & Capabilities pane disappears on the next regeneration.
2. **App ID capabilities: none.** Register `com.sergeyvolf.ShipPeek` with every capability left
   unchecked. Nothing in the app needs an entitlement — it only uses `URLSession` over HTTPS,
   `UserDefaults`, its own Keychain item (`kSecClassGenericPassword`, no access group, so no
   Keychain Sharing), and `CLGeocoder.geocodeAddressString`, which is a plain forward-geocode and
   needs neither the location capability nor an `NSLocation…UsageDescription` key. No push, iCloud,
   App Groups, Sign in with Apple, in-app purchase, or background modes.
   Adding capabilities you don't use is not harmless: each one Xcode has to match against the
   provisioning profile is another way for signing to fail.
3. **App Store Connect record.** appstoreconnect.apple.com → Apps → **+** → New App.
   Bundle ID `com.sergeyvolf.ShipPeek`, SKU anything unique (`shippeek-ios` is fine).
   The **App Name must be unique across the entire App Store** — if "ShipPeek" is taken, pick a
   variant here; it's the store listing name, not the name under the icon (that's
   `CFBundleDisplayName`).
4. **Build number.** Every upload needs a `CURRENT_PROJECT_VERSION` never used before for the
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

The two are independent: someone can be an account user *and* an external tester, and adding
account users does not affect external testing either way.

## Beta App Review (external only)

Lighter than full App Store review — the reviewer is checking that the build launches, works, and
does not obviously violate a guideline, not judging the product. Usually under 24 hours. Once the
first build of a version passes, later builds of the same version normally go straight out.

The overwhelmingly common rejection for an app like this one is **incomplete functionality**: the
reviewer can't get past a screen asking for a credential they don't have.

Fill in **Test Information** once, under the TestFlight tab:

- **Beta App Description**, **Feedback Email**, **Contact info** (name, email, phone) — all required.
- **Sign-in required**: leave this **off**. There is no account system; the toggle expects a
  username and password, and there is nothing to put there.
- **Notes** — this is the field that matters. The API token goes here:

> ShipPeek is a client for the Easyship shipping API. There is no user account; the app asks for an
> Easyship API token on first launch and stores it in the device Keychain.
>
> Use this sandbox token: `sand_...`  — select "Sandbox" as the environment.
>
> Then: Settings tab → set a ship-from address (tap the Country row, it's required) → Save Address.
> Rates tab → choose a destination country and ZIP → enter weight and all three dimensions → enter
> any 8-digit HS code, e.g. 42029100 → Get Rates. Anything still missing is listed under the button.

Use a **sandbox** token here, never a production one — it goes into a form field on Apple's side and
is not a secret you control after that.

## What testers do

Install **TestFlight** from the App Store, then open the invite email or public link.

Each tester needs **their own Easyship API token** — the app stores it in the device Keychain and
has no backend, so there is nothing shared to hand out. Testers without an Easyship account can get
no further than onboarding. Give them a sandbox token directly if you want them past that screen.

Builds expire **90 days** after upload.

## Upload failures

**"No orientations were specified in the … bundle."** `UISupportedInterfaceOrientations` was
missing. Xcode's app template writes it for you; a hand-written `info.properties` block in
`project.yml` does not, so the key simply wasn't there. Both keys are now set — and because
`TARGETED_DEVICE_FAMILY` is `1,2`, the iPad list needs all four orientations so the app can be
resized for multitasking. Dropping to `TARGETED_DEVICE_FAMILY: "1"` (iPhone only) is the other way
to satisfy this, at the cost of iPad support.

**"The bundle version must be higher than the previously uploaded version."** Bump
`CURRENT_PROJECT_VERSION` and regenerate. Build numbers are consumed even by builds that were
rejected during processing, so a failed upload can still burn one.

After any `project.yml` change: `xcodegen generate`, then archive again — editing the generated
`.xcodeproj` directly is pointless, it gets overwritten.
