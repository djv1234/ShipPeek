import SwiftUI

struct CountryOption: Identifiable, Hashable {
    let code: String
    let name: String
    var id: String { code }
}

enum CountryList {
    static let all: [CountryOption] = Locale.Region.isoRegions
        .compactMap { region -> CountryOption? in
            let code = region.identifier
            guard code.count == 2 else { return nil }
            guard let name = Locale.current.localizedString(forRegionCode: code) else { return nil }
            return CountryOption(code: code, name: name)
        }
        .sorted { $0.name < $1.name }
}

/// Replaces free-text country-code entry with a searchable list — avoids typos in the alpha-2 code Easyship expects.
struct CountryPickerField: View {
    @Binding var countryAlpha2: String
    @State private var isPresented = false

    private var selectedName: String? {
        CountryList.all.first { $0.code == countryAlpha2 }?.name
    }

    var body: some View {
        Button {
            isPresented = true
        } label: {
            HStack {
                Text("Country")
                    .foregroundStyle(Color(uiColor: .label))
                Spacer()
                Text(selectedName ?? "Select")
                    .foregroundStyle(.secondary)
            }
        }
        .sheet(isPresented: $isPresented) {
            CountryPickerSheet(countryAlpha2: $countryAlpha2)
        }
    }
}

private struct CountryPickerSheet: View {
    @Binding var countryAlpha2: String
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""

    private var filtered: [CountryOption] {
        guard !query.isEmpty else { return CountryList.all }
        return CountryList.all.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

    var body: some View {
        NavigationStack {
            List(filtered) { option in
                Button {
                    countryAlpha2 = option.code
                    dismiss()
                } label: {
                    HStack {
                        Text(option.name)
                            .foregroundStyle(Color(uiColor: .label))
                        Spacer()
                        if option.code == countryAlpha2 {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
            .searchable(text: $query, prompt: "Search countries")
            .navigationTitle("Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
}
