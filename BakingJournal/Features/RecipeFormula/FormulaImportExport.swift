import SwiftUI
import UniformTypeIdentifiers

struct RecipeBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var data: Data

    init(data: Data) {
        self.data = data
    }

    init(configuration: ReadConfiguration) throws {
        data = configuration.file.regularFileContents ?? Data()
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        FileWrapper(regularFileWithContents: data)
    }
}

struct RecipeExportInstructionSheet: View {
    let onContinue: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: BakingSpace.lg) {
                    BakingSectionCard(title: BakingTerms.recipeExportInstructionTitle) {
                        VStack(alignment: .leading, spacing: BakingSpace.md) {
                            RecipeTransferInstructionRow(number: "1", text: BakingTerms.recipeExportInstructionLocalFile)
                            RecipeTransferInstructionRow(number: "2", text: BakingTerms.recipeExportInstructionImportUse)
                            RecipeTransferInstructionRow(number: "3", text: BakingTerms.recipeExportInstructionKeepFile)
                        }
                        .padding(.horizontal, BakingSpace.md)
                        .padding(.bottom, BakingSpace.md)
                    }
                }
                .padding(.horizontal, BakingLayout.screenHorizontalInset)
                .padding(.top, BakingLayout.contentTopInset)
                .padding(.bottom, BakingSpace.xxl)
            }
        }
        .safeAreaInset(edge: .bottom) {
            BakingBottomActionButton(
                title: BakingTerms.recipeExportInstructionContinue,
                accessibilityLabel: BakingTerms.recipeExportInstructionContinue,
                action: onContinue
            )
        }
        .background(Color.brandBackground)
        .presentationDetents([.medium])
    }
}

struct RecipeTransferInstructionRow: View {
    let number: String
    let text: String

    var body: some View {
        HStack(alignment: .top, spacing: BakingSpace.sm) {
            Text(number)
                .font(BakingTypography.iconCaption)
                .foregroundStyle(Color.brandPrimary)
                .frame(width: 22, height: 22)
                .bakingSurface(.readOnly)
                .accessibilityHidden(true)

            Text(text)
                .font(BakingTypography.appPrimaryText)
                .foregroundStyle(Color.brandText)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
