import SwiftUI

struct WritingStyleView: View {
    @EnvironmentObject var settingsStore: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add your own instructions to guide how emails are written. For example: \"Keep it casual\" or \"Always sign off with Cheers\".")
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            ZStack(alignment: .topLeading) {
                if settingsStore.customWritingInstructions.isEmpty {
                    // Matches NSTextView's default insets so it sits where
                    // the cursor would be: ~5px lineFragmentPadding
                    // horizontally + ~8px textContainerInset vertically.
                    Text("e.g. Be concise and friendly, use British English...")
                        .font(.body)
                        .foregroundStyle(.tertiary)
                        .padding(.leading, 5)
                        .padding(.top, 8)
                        .allowsHitTesting(false)
                }

                TextEditor(text: $settingsStore.customWritingInstructions)
                    .font(.body)
                    .scrollContentBackground(.hidden)
            }
            .padding(4)
            .frame(maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color(nsColor: .textBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(nsColor: .separatorColor), lineWidth: 1)
            )
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }
}
