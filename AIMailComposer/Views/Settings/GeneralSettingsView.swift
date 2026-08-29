import AppKit
import SwiftUI

struct GeneralSettingsView: View {
    @EnvironmentObject var settingsStore: SettingsStore
    @EnvironmentObject var updateChecker: UpdateChecker

    private var shortcutDisplay: String {
        HotkeyService.shortcutDisplayString(
            keyCode: UInt32(settingsStore.hotkeyKeyCode),
            modifiers: UInt32(settingsStore.hotkeyModifiers)
        )
    }

    var body: some View {
        Form {
            Section("How to Use") {
                step(1, "Open or reply to an email in Apple Mail")
                step(2, "Press **\(shortcutDisplay)** to open the AI composer")
                step(3, "Describe what you want to say")
                step(4, "Your reply is generated and inserted into the draft")
            }

            Section {
                LabeledContent("Keyboard shortcut") {
                    ShortcutRecorderView(settingsStore: settingsStore)
                }
            } footer: {
                Text("Click the shortcut, then press a new key combination. It works from anywhere.")
            }

            Section {
                Toggle("Launch at login", isOn: Binding(
                    get: { settingsStore.launchAtLogin },
                    set: { settingsStore.setLaunchAtLogin($0) }
                ))
                .toggleStyle(.switch)
            }

            Section("Updates") {
                LabeledContent("Version \(updateChecker.currentVersion)") {
                    updateStatusView
                }
            }
        }
        .formStyle(.grouped)
    }

    private func step(_ number: Int, _ text: LocalizedStringKey) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(number)")
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.accentColor))

            Text(text)
                .font(.system(size: 13))
                .foregroundStyle(.primary)
        }
        .padding(.vertical, 1)
    }

    // MARK: - Updates

    @ViewBuilder
    private var updateStatusView: some View {
        switch updateChecker.state {
        case .idle:
            Button("Check for Updates") {
                updateChecker.checkForUpdates(manual: true)
            }
            .controlSize(.small)

        case .upToDate:
            HStack(spacing: 8) {
                Text("Up to date")
                    .foregroundStyle(.secondary)
                Button("Check Again") {
                    updateChecker.checkForUpdates(manual: true)
                }
                .controlSize(.small)
            }

        case .checking:
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Checking…")
                    .foregroundStyle(.secondary)
            }

        case .downloading:
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Downloading v\(updateChecker.latestVersion ?? "")…")
                    .foregroundStyle(.secondary)
            }

        case .readyToInstall:
            Button("Relaunch to Update to v\(updateChecker.latestVersion ?? "")") {
                updateChecker.install()
            }
            .controlSize(.small)

        case .installing:
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                Text("Installing…")
                    .foregroundStyle(.secondary)
            }

        case .failed(let message):
            VStack(alignment: .trailing, spacing: 4) {
                Text(message)
                    .font(.system(size: 11))
                    .foregroundStyle(.red)
                    .lineLimit(2)
                Button("Retry") {
                    updateChecker.checkForUpdates(manual: true)
                }
                .controlSize(.small)
            }
        }
    }
}

// MARK: - Shortcut Recorder

private struct ShortcutRecorderView: View {
    @ObservedObject var settingsStore: SettingsStore
    @State private var isRecording = false
    @State private var eventMonitor: Any?

    private var displayString: String {
        HotkeyService.shortcutDisplayString(
            keyCode: UInt32(settingsStore.hotkeyKeyCode),
            modifiers: UInt32(settingsStore.hotkeyModifiers)
        )
    }

    var body: some View {
        Button {
            if isRecording {
                stopRecording()
            } else {
                startRecording()
            }
        } label: {
            Text(isRecording ? "Press keys…" : displayString)
                .font(isRecording
                    ? .system(size: 12)
                    : .system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(isRecording ? .secondary : .primary)
                .frame(minWidth: 84)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(Color.primary.opacity(isRecording ? 0.03 : 0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(
                            isRecording ? Color.accentColor : Color.primary.opacity(0.12),
                            lineWidth: 1
                        )
                )
        }
        .buttonStyle(.plain)
        .help(isRecording
            ? "Press the new shortcut, or Esc to cancel"
            : "Click to record a new shortcut")
        .onDisappear {
            stopRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Escape cancels recording
            if event.keyCode == 53 { // kVK_Escape
                stopRecording()
                return nil
            }

            // Require at least one modifier key
            let mods = event.modifierFlags.intersection([.command, .option, .control, .shift])
            guard !mods.isEmpty else { return event }

            let carbonMods = HotkeyService.carbonModifiers(from: event.modifierFlags)
            settingsStore.setHotkey(keyCode: Int(event.keyCode), modifiers: Int(carbonMods))
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }
}
