import SwiftUI

struct WritingStyleView: View {
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add your own instructions to guide how emails are written. For example: \"Keep it casual\" or \"Always sign off with Cheers\".")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            TextEditor(text: $settingsStore.customWritingInstructions)
                .font(.body)
                .frame(maxHeight: .infinity)
                .scrollContentBackground(.hidden)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(nsColor: .textBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
                )
                .overlay(alignment: .topLeading) {
                    if settingsStore.customWritingInstructions.isEmpty {
                        Text("e.g. Be concise and friendly, use British English...")
                            .foregroundStyle(.tertiary)
                            .padding(.leading, 13)
                            .padding(.top, 16)
                            .allowsHitTesting(false)
                    }
                }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
