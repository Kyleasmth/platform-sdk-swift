import SwiftUI
import YouVersionPlatformCore
import YouVersionPlatformUI

extension BibleReaderViewModel {

    func loadVersionsList() {
        guard permittedVersionIdsAndLanguages.isEmpty else {
            return
        }
        Task {
            do {
                let versions = try await YouVersionAPI.Bible.versions(fields: [.id, .languageTag, .localizedTitle])  // INSUFFICIENT for all use cases. Keep going.
                let deduplicated = versions
                    .sorted { $0.id < $1.id }
                    .reduce(into: [BibleVersion]()) { result, version in
                        if !result.contains(where: { $0.id == version.id }) {
                            result.append(version)
                        }
                    }

                let sorted = deduplicated.sorted {
                    ($0.title ?? "").localizedCaseInsensitiveCompare($1.title ?? "") == .orderedAscending
                }
                await MainActor.run {
                    permittedVersionIdsAndLanguages = sorted
                }
            } catch {
                print("Error loading versions: \(error)")
                await MainActor.run {
                    showGenericAlert = true
                    textForGenericAlertTitle = .localized("generic.error")
                    textForGenericAlertBody = "It was not possible to get the list of Bible versions. Please try again later."
                }
            }
        }
    }

    public var bibleVersionStatisticsPromo: String {
        guard !permittedVersionIdsAndLanguages.isEmpty else {
            return ""
        }
        let num = permittedVersionIdsAndLanguages.count
        let uniqueLanguages = Set(permittedVersionIdsAndLanguages.map { $0.languageTag }).count
        return String(format: .localized("versionList.statisticsFormat"), num, uniqueLanguages)
    }

    @MainActor
    public func downloadStatus(for id: Int) async -> BibleVersionRepository.BibleVersionDownloadStatus {
        if versionRepository.downloadStatus(for: id) == .downloaded {
            return .downloaded
        }
        // TEMPORARY
//        if let overview = permittedVersions.first(where: { $0.id == id }) {
//            if overview.downloadable == true {
//                return .downloadable
//            }
//        }
        return .notDownloadable
    }

    public func switchToVersion(_ versionId: Int) {
        Task {
            let ref = BibleReference(versionId: versionId, bookUSFM: reference.bookUSFM, chapter: reference.chapter)
            await onHeaderSelectionChange(ref)
        }
    }

    public func handleVersionPickerTap(_ versionId: Int) {
        Task {
            do {
                showFullProgressViewOverlay = true
                defer {
                    showFullProgressViewOverlay = false
                }
                let version = try await versionRepository.version(withId: versionId)
                selectedVersion = version
                versionsStackPush(to: .versionInfo)
            } catch {
                print("Error loading version: \(error)")
                showGenericAlert = true
                textForGenericAlertTitle = .localized("generic.error")
                textForGenericAlertBody = "It was not possible to access this Bible version. Please try again later."
            }
        }
    }

}
