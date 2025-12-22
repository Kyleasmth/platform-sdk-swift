import SwiftUI
import YouVersionPlatformCore
import YouVersionPlatformUI

extension BibleReaderViewModel {
    // MARK: - Preview helper

    public static var preview: BibleReaderViewModel {
        // Create a minimal BibleReaderViewModel for preview purposes
        let vm = BibleReaderViewModel(reference: BibleReference(versionId: 1, bookUSFM: "GEN", chapter: 1))

        let d = "{\"id\": 111, \"language_code\": \"eng\"}".data(using: .utf8)!
        let minimal = try? JSONDecoder().decode(BibleVersion.self, from: d)
        vm.permittedVersionIdsAndLanguages = [minimal!]

        let previewVersion = BibleVersion.preview
        vm.version = previewVersion
        vm.myVersions = [previewVersion]
        vm.selectedVersion = previewVersion

        let footnoteReference = BibleReference(versionId: 111, bookUSFM: "JHN", chapter: 21, verse: 1)
        vm.footnotesToDisplay = [
            BibleFootnote(text: BibleAttributedString("Footnote text goes here."), reference: footnoteReference),
            BibleFootnote(text: BibleAttributedString("Second Footnote text goes here. This time the footnote is fairly long."), reference: footnoteReference)
        ]
        return vm
    }

}
