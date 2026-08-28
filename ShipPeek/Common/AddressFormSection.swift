import SwiftUI

/// Reusable address input fields, shared by Settings (ship-from) and Rate Calculator (destination).
struct AddressFormSection: View {
    @Binding var address: Address

    var body: some View {
        TextField("Contact name", text: $address.contactName)
        TextField("Company (optional)", text: $address.companyName)
        TextField("Address line 1", text: $address.line1)
        TextField("Address line 2 (optional)", text: $address.line2)
        TextField("City", text: $address.city)
        TextField("State / Province", text: $address.state)
        TextField("Postal code", text: $address.postalCode)
        CountryPickerField(countryAlpha2: $address.countryAlpha2)
    }
}
