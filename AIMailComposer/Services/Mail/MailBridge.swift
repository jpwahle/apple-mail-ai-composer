import Foundation
import AppKit

enum MailBridgeError: LocalizedError {
    case scriptFailed(String)
    case noComposer
    case mailNotRunning
    case parseError(String)

    var errorDescription: String? {
        switch self {
        case .scriptFailed(let msg):
            return "AppleScript error: \(msg)"
        case .noComposer:
            return "Open a compose window in Mail first, then try again."
        case .mailNotRunning:
            return "Mail is not running. Open Mail and try again."
        case .parseError(let msg):
            return "Failed to parse Mail context: \(msg)"
        }
    }
}

final class MailBridge {
    static func executeAppleScript(_ source: String) async throws -> String {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                var error: NSDictionary?
                guard let script = NSAppleScript(source: source) else {
                    continuation.resume(throwing: MailBridgeError.scriptFailed("Failed to create script"))
                    return
                }
                let result = script.executeAndReturnError(&error)
                if let error = error {
                    let message = error[NSAppleScript.errorMessage] as? String ?? "Unknown AppleScript error"
                    continuation.resume(throwing: MailBridgeError.scriptFailed(message))
                } else {
                    continuation.resume(returning: result.stringValue ?? "")
                }
            }
        }
    }

    static func isMailRunning() async -> Bool {
        do {
            let result = try await executeAppleScript(MailScripts.checkMailRunning)
            return result.lowercased() == "true"
        } catch {
            return false
        }
    }

    /// Pull context from the currently open Mail compose window, falling
    /// back to the Accessibility reader when Mail's `outgoing messages`
    /// AppleScript collection is empty (recent macOS versions). Never
    /// blocks on Accessibility permission: if AX isn't granted, the
    /// AppleScript context is returned as-is so the UI can offer a
    /// dismissible banner instead of a permission wall.
    ///
    /// Never reads from the message list — the compose window is the source
    /// of truth.
    static func fetchComposerContext() async throws -> ComposerContext {
        guard await isMailRunning() else {
            throw MailBridgeError.mailNotRunning
        }

        let raw = try await executeAppleScript(MailScripts.fetchComposerContext)

        if raw.hasPrefix("ERROR:NO_COMPOSER") {
            throw MailBridgeError.noComposer
        }

        let context = try MailThreadParser.parseComposerContext(raw)

        // If Pass 1 (outgoing messages) found nothing but Pass 2 identified
        // a compose window by name, the AppleScript path is broken (recent
        // macOS versions). Fall back to the Accessibility reader when
        // permission is granted; otherwise return the context as-is.
        if context.recipients.isEmpty && context.currentDraft.isEmpty {
            return enrichViaAccessibility(context: context)
        }

        return context
    }

    /// Opportunistically enrich the context via the AX reader. If AX isn't
    /// trusted or no compose window is found, the original context is
    /// returned unchanged — never throws.
    private static func enrichViaAccessibility(context: ComposerContext) -> ComposerContext {
        guard AXPermissionChecker.isGranted() else {
            return context
        }

        guard let ax = AccessibilityReader.readComposeWindow() else {
            // AX is granted but no compose window was found — return the
            // original (possibly empty) context rather than failing.
            return context
        }

        let thread = context.thread
        let subject = ax.subject.isEmpty ? context.subject : ax.subject

        return ComposerContext(
            recipients: ax.recipients,
            subject: subject,
            currentDraft: ax.draftContent,
            thread: thread,
            composeWindowFrame: context.composeWindowFrame
        )
    }

    /// Write the reply directly into the current Mail compose window.
    ///
    /// Three passes, mirroring the read path's AppleScript → AX fallback:
    ///   1. Mail scripting API (`content of outgoing message 1`) — works on
    ///      older macOS versions.
    ///   2. AX write into the compose body — recent macOS versions return an
    ///      empty `outgoing messages` collection, so pass 1 silently no-ops
    ///      there (the same breakage `fetchComposerContext` works around).
    ///   3. Synthetic ⌘V into the body — last resort when the body is
    ///      focused but rejects the AX text write.
    /// The clipboard is populated first so a manual paste works no matter
    /// which pass ran.
    @MainActor
    static func insertReply(_ text: String) async {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)

        // Pass 1: Mail scripting API.
        let scriptResult = (try? await executeAppleScript(MailScripts.insertReply(text))) ?? ""
        if scriptResult.hasPrefix("INSERTED") {
            activateMail()
            return
        }

        // Pass 2: AX writer. Activate Mail first so focusing the compose
        // body sticks. The walk is IPC-heavy — keep it off the main thread.
        activateMail()
        let result = await Task.detached(priority: .userInitiated) {
            AccessibilityWriter.insertIntoComposeBody(text)
        }.value

        switch result {
        case .inserted, .failed:
            // .failed leaves the reply on the clipboard, the pre-existing
            // behavior for a missing compose window.
            return
        case .bodyFocused:
            // Pass 3: the body has focus but rejected the AX write — paste
            // the clipboard into it. The short delay lets Mail finish
            // activating before the key events arrive.
            guard let mail = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.mail").first else {
                return
            }
            try? await Task.sleep(nanoseconds: 250_000_000)
            AccessibilityWriter.pasteCommandV(pid: mail.processIdentifier)
        }
    }

    @MainActor
    private static func activateMail() {
        if let mailApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.mail").first {
            mailApp.activate()
        }
    }
}
