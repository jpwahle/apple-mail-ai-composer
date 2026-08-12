import Foundation
import AppKit

/// Reads the Mail compose window's fields via the Accessibility (AX) API.
///
/// Recent macOS versions broke Mail's `outgoing messages` AppleScript
/// collection — it returns 0 even with a compose window open. This reader
/// traverses Mail's AX tree to recover the subject, recipients, and draft
/// content directly from the window's text fields.
///
/// Read-only: never sends keystrokes or modifies the compose window.
///
/// Performance: every AX attribute read is an IPC round trip, and the main
/// viewer window's tree (the message table) can be huge, so the reader
/// (a) skips windows identified as `Mail.messageViewer.window` outright,
/// (b) collects subject, recipients, and draft in a single recursive walk,
/// and (c) sets a messaging timeout so a busy Mail can't hang the panel.
enum AccessibilityReader {

    struct ComposeContext {
        let subject: String
        let recipients: [String]
        let draftContent: String
    }

    /// Cap AX reads at this many seconds so a busy Mail doesn't stall the
    /// panel. Individual attribute calls return `kAXErrorCannotComplete`
    /// past it, which the walkers treat as "no value".
    private static let messagingTimeout: Float = 1.5

    private static let recipientFieldIDs: Set<String> = [
        "Mail.toField", "Mail.ccField", "Mail.bccField",
    ]

    /// Traverse all Mail windows and return the context of the first one
    /// that looks like a compose window (has a `Mail.subjectField` or
    /// `Mail.toField`). Returns `nil` if no compose window is found or if
    /// the app lacks Accessibility permission.
    static func readComposeWindow() -> ComposeContext? {
        guard AXIsProcessTrusted() else { return nil }

        guard let mailApp = NSRunningApplication.runningApplications(withBundleIdentifier: "com.apple.mail").first else {
            return nil
        }
        let app = AXUIElementCreateApplication(mailApp.processIdentifier)
        AXUIElementSetMessagingTimeout(app, messagingTimeout)

        var windowsRef: CFTypeRef?
        AXUIElementCopyAttributeValue(app, kAXWindowsAttribute as CFString, &windowsRef)
        guard let windows = windowsRef as? [AXUIElement] else { return nil }

        for window in windows {
            // Skip the main viewer window by identifier — its tree contains
            // the message table and can be enormous.
            if let id = axIdentifier(window), id == "Mail.messageViewer.window" {
                continue
            }
            if let ctx = readWindow(window) {
                return ctx
            }
        }
        return nil
    }

    // MARK: - Per-window

    /// Returns context if the given AX window is a Mail compose window.
    /// Collects subject, recipients, and draft in a single recursive walk
    /// instead of one traversal per field.
    private static func readWindow(_ window: AXUIElement) -> ComposeContext? {
        var acc = Walker()
        walk(window, collectingBody: false, into: &acc)
        guard acc.foundComposeMarker else { return nil }

        let draft = acc.draftLines
            .joined(separator: "\n")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return ComposeContext(
            subject: acc.subject,
            recipients: acc.recipients,
            draftContent: draft
        )
    }

    // MARK: - Single-walk accumulator

    private struct Walker {
        var subject = ""
        var recipients: [String] = []
        var draftLines: [String] = []
        var foundComposeMarker = false
    }

    /// One depth-first pass that records the subject, recipient addresses,
    /// and — once the `message body` web area is entered — all draft text.
    private static func walk(
        _ element: AXUIElement,
        collectingBody: Bool,
        into acc: inout Walker
    ) {
        let role = axRole(element)
        let identifier = axIdentifier(element)

        if let id = identifier {
            if id == "Mail.subjectField" || id == "Mail.toField" {
                acc.foundComposeMarker = true
            }
            if id == "Mail.subjectField" {
                acc.subject = axValue(element) ?? ""
            }
            if recipientFieldIDs.contains(id) {
                if let addr = extractAddress(from: element), !addr.isEmpty {
                    acc.recipients.append(addr)
                }
            }
        }

        // Enter the draft body web area — collect text from it and its
        // descendants only, so subject/recipient text doesn't pollute it.
        var inBody = collectingBody
        if !inBody, let r = role, r == "AXWebArea" {
            if axDescription(element) == "message body" {
                inBody = true
            }
        }

        if inBody, let r = role, r == "AXStaticText" || r == "AXTextArea" {
            if let val = axValue(element), !val.isEmpty {
                acc.draftLines.append(val)
            }
        }

        var childrenRef: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXChildrenAttribute as CFString, &childrenRef)
        if let children = childrenRef as? [AXUIElement] {
            for child in children {
                walk(child, collectingBody: inBody, into: &acc)
            }
        }
    }

    // MARK: - Recipients

    /// Recipient fields contain a child `AXStaticText` with the formatted
    /// "Name <email>" string; the field's own value is just an attachment
    /// placeholder. Walk direct children to find the static text.
    private static func extractAddress(from field: AXUIElement) -> String? {
        var childrenRef: CFTypeRef?
        AXUIElementCopyAttributeValue(field, kAXChildrenAttribute as CFString, &childrenRef)
        guard let children = childrenRef as? [AXUIElement] else { return nil }

        var parts: [String] = []
        for child in children {
            if let role = axRole(child), role == "AXStaticText" {
                if let val = axValue(child), !val.isEmpty {
                    parts.append(val)
                }
            }
        }
        return parts.isEmpty ? nil : parts.joined(separator: ", ")
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
