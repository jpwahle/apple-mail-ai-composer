import Foundation
import AppKit

/// Writes the generated reply into the Mail compose window via the
/// Accessibility (AX) API.
///
/// Counterpart to `AccessibilityReader`: recent macOS versions broke Mail's
/// `outgoing messages` AppleScript collection, so `set content of outgoing
/// message 1` silently does nothing even with a compose window open. This
/// writer locates the compose window's "message body" web area and prepends
/// the reply there, matching what the AppleScript path does on older systems.
///
/// WebKit editors reject writes to `AXValue`; the broadly supported edit
/// primitive is replacing the selection via `AXSelectedText`, so the writer
/// collapses the selection to the start of the body and replaces that empty
/// selection with the reply.
enum AccessibilityWriter {

    enum WriteResult {
        /// The reply was written into the draft.
        case inserted
        /// The compose body was found and focused, but rejected the AX text
        /// write — a synthetic paste into the (now focused) body will land
        /// correctly.
        case bodyFocused
        /// No compose body was found, or AX permission is missing.
        case failed
    }

    /// Cap AX calls at this many seconds so a busy Mail doesn't stall the
    /// insert action. Mirrors `AccessibilityReader.messagingTimeout`.
    private static let messagingTimeout: Float = 1.5

    /// Prepend `text` (plus a blank line) above the existing content of the
    /// first compose window's message body.
    static func insertIntoComposeBody(_ text: String) -> WriteResult {
        guard AXIsProcessTrusted() else { return .failed }

        guard let mailApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.mail").first else {
            return .failed
        }
        // The timeout must be set on the system-wide element: set on any
        // other element it only caps messages to that element.
        AXUIElementSetMessagingTimeout(AXUIElementCreateSystemWide(), messagingTimeout)

        let app = AXUIElementCreateApplication(mailApp.processIdentifier)

        var windowsRef: CFTypeRef?
        AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef)
        guard let windows = windowsRef as? [AXUIElement] else { return .failed }

        for window in windows {
            // Skip the main viewer window by identifier — its tree contains
            // the message table and can be enormous.
            if let id = axIdentifier(window), id == "Mail.messageViewer.window" {
                continue
            }
            guard let body = findMessageBody(in: window) else { continue }
            AXUIElementPerformAction(window, kAXRaiseAction as CFString)
            return insert(text, into: body)
        }
        return .failed
    }

    /// Post a ⌘V key-down/key-up pair to Mail. Used as a last resort when
    /// the compose body is focused but rejected the AX text write; the
    /// caller is responsible for having the reply on the clipboard.
    static func pasteCommandV(pid: pid_t) {
        let source = CGEventSource(stateID: .combinedSessionState)
        let vKey: CGKeyCode = 9 // kVK_ANSI_V
        guard let down = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: true),
              let up = CGEvent(keyboardEventSource: source, virtualKey: vKey, keyDown: false) else {
            return
        }
        down.flags = .maskCommand
        up.flags = .maskCommand
        down.postToPid(pid)
        up.postToPid(pid)
    }

    // MARK: - Body lookup

    /// The compose body is an `AXWebArea` described as "message body".
    /// Prefer its inner `AXTextArea` (the editable element); fall back to
    /// the web area itself.
    private static func findMessageBody(in window: AXUIElement) -> AXUIElement? {
        let webArea = findDescendant(of: window) { el in
            axRole(el) == "AXWebArea" && axDescription(el) == "message body"
        }
        guard let webArea else { return nil }

        if let textArea = findDescendant(of: webArea, where: { axRole($0) == "AXTextArea" }) {
            return textArea
        }
        return webArea
    }

    private static func findDescendant(
        of element: AXUIElement,
        where predicate: (AXUIElement) -> Bool
    ) -> AXUIElement? {
        if predicate(element) { return element }
        var childrenRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef)
        guard let children = childrenRef as? [AXUIElement] else { return nil }
        for child in children {
            if let match = findDescendant(of: child, where: predicate) {
                return match
            }
        }
        return nil
    }

    // MARK: - Write

    /// Focus the body, collapse the selection to the very start, and replace
    /// that empty selection with the reply — i.e. prepend above any quoted
    /// thread, matching the AppleScript path's
    /// `newText & return & return & oldContent`.
    private static func insert(_ text: String, into body: AXUIElement) -> WriteResult {
        AXUIElementSetAttributeValue(body, kAXFocusedAttribute as CFString, kCFBooleanTrue)

        var start = CFRange(location: 0, length: 0)
        if let rangeValue = AXValueCreate(.cfRange, &start) {
            AXUIElementSetAttributeValue(body, kAXSelectedTextRangeAttribute as CFString, rangeValue)
        }

        let payload = text + "\n\n"
        let err = AXUIElementSetAttributeValue(body, kAXSelectedTextAttribute as CFString, payload as CFString)
        guard err == .success else { return .bodyFocused }

        // WebKit can report success without applying the edit — read back
        // and check the reply actually landed. A nil value means the element
        // doesn't expose its text; trust the success code then.
        if let value = axValue(body) {
            let probe = text
                .components(separatedBy: .newlines)
                .first { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            if let probe, !value.contains(probe) {
                return .bodyFocused
            }
        }
        return .inserted
    }

    // MARK: - AX helpers

    private static func axRole(_ el: AXUIElement) -> String? {
        var ref: CFTypeRef?
        AXUIElementCopyAttributeValue(el, kAXRoleAttribute as CFString, &ref)
        return ref as? String
    }

    private static func axDescription(_ el: AXUIElement) -> String? {
        var ref: CFTypeRef?
        AXUIElementCopyAttributeValue(el, kAXDescriptionAttribute as CFString, &ref)
        return ref as? String
    }

    private static func axValue(_ el: AXUIElement) -> String? {
        var ref: CFTypeRef?
        AXUIElementCopyAttributeValue(el, kAXValueAttribute as CFString, &ref)
        return ref as? String
    }

    private static func axIdentifier(_ el: AXUIElement) -> String? {
        var ref: CFTypeRef?
        AXUIElementCopyAttributeValue(el, kAXIdentifierAttribute as CFString, &ref)
        return ref as? String
    }
}
