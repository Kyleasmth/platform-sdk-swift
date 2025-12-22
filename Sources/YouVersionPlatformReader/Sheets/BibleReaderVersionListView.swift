import SwiftUI
import YouVersionPlatformCore
import YouVersionPlatformUI

public struct BibleReaderVersionListView: View {
    @Environment(BibleReaderViewModel.self) private var viewModel
    @State private var searchText = ""
    //@State private var filteredVersions: [BibleVersion]? = nil
    @State private var languageVersionsMap: [String: [BibleVersion]] = [:]

    public var body: some View {
        VStack(spacing: 0) {
            if viewModel.bibleVersionStatisticsPromo.isEmpty {
                Color.clear.frame(height: 72)
            }
            searchInput
            languageDisplay
                .onTapGesture {
                    viewModel.versionsStackPush(to: .languages)
                }
            Group {
                let versions = filteredVersions
                if versions == nil {
                    VStack {
                        Spacer()
                        ProgressView()
                            .tint(viewModel.readerTextMutedColor)
                        Spacer()
                        Spacer()
                    }
                } else if versions?.isEmpty == true {
                    Spacer()
                    Text("No versions are available.")
                    Spacer()
                    Spacer()
                } else {
                    List(versions!, id: \.id) { v in
                        BibleVersionOverviewListItem(item: v)
                            .listRowBackground(viewModel.readerCanvasPrimaryColor)
                            .listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                            .onTapGesture {
                                viewModel.handleVersionPickerTap(v.id)
                            }
                    }
                    .listStyle(PlainListStyle())
                }
            }
        }
#if os(iOS)
        .toolbar {
            if #available(iOS 15, *) {
                ToolbarItem(placement: .title) {
                    Text(viewModel.bibleVersionStatisticsPromo)
                        .fontWeight(.medium)
                        .foregroundStyle(viewModel.readerTextPrimaryColor)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
#endif
        .customBackButton {
            viewModel.versionsStackPop()
        }
        .foregroundStyle(viewModel.readerTextPrimaryColor)
        .background(viewModel.readerCanvasPrimaryColor)
        .onAppear {
            //filteredVersions = nil
//            Task {
//                await loadFilteredVersions(language: activeLanguage)
//            }
        }
    }

    private var searchInput: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .imageScale(.medium)
                .foregroundStyle(.secondary)
            TextField(
                "",
                text: $searchText,
                prompt: Text(String.localized("versionList.searchPlaceholder"))
                    .foregroundStyle(viewModel.readerTextMutedColor)
            )
            #if os(iOS)
            .textInputAutocapitalization(.never)
            #endif
            .autocorrectionDisabled(true)
            .accessibilityLabel(String.localized("versionList.searchPlaceholder"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(viewModel.readerButtonPrimaryColor)
        )
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
    }

    // We might need to look up the language name from our own API instead of this.
    private func languageName(_ lang: String) -> String {
        Locale.current.localizedString(forLanguageCode: lang) ?? lang
    }

    private var activeLanguage: String {
        viewModel.chosenLanguage ?? viewModel.version?.languageTag ?? "en"
    }
    private var languageDisplay: some View {
        let language = activeLanguage
        let versionsInLanguage = viewModel.permittedVersionIdsAndLanguages.filter { $0.languageTag == language }
        return HStack {
            Image(systemName: "globe")
            Text(languageName(language))
            Text(String(versionsInLanguage.count))
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 2)
                .background(
                    Capsule()
                        .fill(viewModel.readerButtonPrimaryColor)
                )
            Image(systemName: "chevron.right")
            Spacer()
        }
        .padding()
    }

    private var filteredVersions: [BibleVersion]? {
        let language = activeLanguage
        // if we don't have it cached yet, start fetch in background, and return nil to show the ProgressView.
        guard let versions = languageVersionsMap[language] else {
            Task {
                print("Fetching versions for language: \(language)")
                guard let versions = try? await YouVersionAPI.Bible.versions(forLanguageTag: language, fields: [.id, .abbreviation, .title, .localizedTitle, .localizedAbbreviation]) else {
                    print("Could not load versions for language: \(language)")
                    languageVersionsMap[language] = []
                    return
                }
                await MainActor.run {
                    languageVersionsMap[language] = versions
                }
            }
            return nil
        }

        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !query.isEmpty else {
            return versions
        }
        return versions.filter { v in
//            guard v.languageTag == language else {
//                return false
//            }
            let title = (v.localizedTitle ?? v.title ?? "").lowercased()
            let abbr = (v.localizedAbbreviation ?? v.abbreviation ?? String(v.id)).lowercased()
            let lang = (v.languageTag ?? "")
            return title.contains(query) || abbr.contains(query) || lang.contains(query)
        }
    }

}

#Preview {
    BibleReaderVersionListView()
        .environment(BibleReaderViewModel.preview)
}
