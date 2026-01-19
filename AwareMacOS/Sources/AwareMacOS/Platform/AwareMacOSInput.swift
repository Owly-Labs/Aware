//
//  AwareMacOSInput.swift
//  AwareMacOS
//
//  CGEvent-based input simulation for mouse clicks and keyboard typing.
//  Used for LLM-controlled UI testing on macOS.
//

#if os(macOS)
import AppKit
import Foundation
import AwareCore

// MARK: - Keyboard Input Helper

/// Helper for synthesizing keyboard input via CGEvent
@MainActor
public struct AwareMacOSKeyboard {
    /// Map character to virtual key code and shift state
    public static func keyCodeForCharacter(_ char: Character) -> (CGKeyCode, Bool)? {
        keyMap[char]
    }

    /// Create Unicode input events for characters not in standard key map
    public static func createUnicodeKeyEvents(for char: Character) -> [CGEvent] {
        var events: [CGEvent] = []

        let unicodeScalar = char.unicodeScalars.first?.value ?? 0

        if let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true) {
            var unicodeChar = UniChar(unicodeScalar)
            event.keyboardSetUnicodeString(stringLength: 1, unicodeString: &unicodeChar)
            events.append(event)
        }
        if let event = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) {
            events.append(event)
        }

        return events
    }

    // Standard US keyboard layout mapping
    private static let keyMap: [Character: (CGKeyCode, Bool)] = [
        // Letters (lowercase = no shift, uppercase = shift)
        "a": (0x00, false), "A": (0x00, true),
        "b": (0x0B, false), "B": (0x0B, true),
        "c": (0x08, false), "C": (0x08, true),
        "d": (0x02, false), "D": (0x02, true),
        "e": (0x0E, false), "E": (0x0E, true),
        "f": (0x03, false), "F": (0x03, true),
        "g": (0x05, false), "G": (0x05, true),
        "h": (0x04, false), "H": (0x04, true),
        "i": (0x22, false), "I": (0x22, true),
        "j": (0x26, false), "J": (0x26, true),
        "k": (0x28, false), "K": (0x28, true),
        "l": (0x25, false), "L": (0x25, true),
        "m": (0x2E, false), "M": (0x2E, true),
        "n": (0x2D, false), "N": (0x2D, true),
        "o": (0x1F, false), "O": (0x1F, true),
        "p": (0x23, false), "P": (0x23, true),
        "q": (0x0C, false), "Q": (0x0C, true),
        "r": (0x0F, false), "R": (0x0F, true),
        "s": (0x01, false), "S": (0x01, true),
        "t": (0x11, false), "T": (0x11, true),
        "u": (0x20, false), "U": (0x20, true),
        "v": (0x09, false), "V": (0x09, true),
        "w": (0x0D, false), "W": (0x0D, true),
        "x": (0x07, false), "X": (0x07, true),
        "y": (0x10, false), "Y": (0x10, true),
        "z": (0x06, false), "Z": (0x06, true),

        // Numbers
        "0": (0x1D, false), ")": (0x1D, true),
        "1": (0x12, false), "!": (0x12, true),
        "2": (0x13, false), "@": (0x13, true),
        "3": (0x14, false), "#": (0x14, true),
        "4": (0x15, false), "$": (0x15, true),
        "5": (0x17, false), "%": (0x17, true),
        "6": (0x16, false), "^": (0x16, true),
        "7": (0x1A, false), "&": (0x1A, true),
        "8": (0x1C, false), "*": (0x1C, true),
        "9": (0x19, false), "(": (0x19, true),

        // Common punctuation
        " ": (0x31, false),  // Space
        "-": (0x1B, false), "_": (0x1B, true),
        "=": (0x18, false), "+": (0x18, true),
        "[": (0x21, false), "{": (0x21, true),
        "]": (0x1E, false), "}": (0x1E, true),
        "\\": (0x2A, false), "|": (0x2A, true),
        ";": (0x29, false), ":": (0x29, true),
        "'": (0x27, false), "\"": (0x27, true),
        ",": (0x2B, false), "<": (0x2B, true),
        ".": (0x2F, false), ">": (0x2F, true),
        "/": (0x2C, false), "?": (0x2C, true),
        "`": (0x32, false), "~": (0x32, true),

        // Special keys
        "\n": (0x24, false), // Return
        "\t": (0x30, false), // Tab
    ]
}

// MARK: - Mouse Click Simulation

/// Helper for synthesizing mouse clicks via CGEvent
@MainActor
public struct AwareMacOSMouse {
    /// Simulate a click at a screen point
    public static func click(at point: CGPoint) async -> Bool {
        guard let mouseDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left),
              let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) else {
            return false
        }

        mouseDown.post(tap: .cghidEventTap)
        try? await Task.sleep(nanoseconds: 50_000_000) // 50ms delay
        mouseUp.post(tap: .cghidEventTap)
        return true
    }

    /// Simulate a long press at a screen point
    public static func longPress(at point: CGPoint, duration: TimeInterval = 0.5) async -> Bool {
        guard let mouseDown = CGEvent(mouseEventSource: nil, mouseType: .leftMouseDown, mouseCursorPosition: point, mouseButton: .left),
              let mouseUp = CGEvent(mouseEventSource: nil, mouseType: .leftMouseUp, mouseCursorPosition: point, mouseButton: .left) else {
            return false
        }

        mouseDown.post(tap: .cghidEventTap)
        try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        mouseUp.post(tap: .cghidEventTap)
        return true
    }

    /// Convert view frame coordinates to screen coordinates
    public static func viewToScreenPoint(frame: CGRect, in window: NSWindow?) -> CGPoint? {
        guard let window = window else { return nil }

        let centerX = frame.origin.x + frame.width / 2
        let centerY = frame.origin.y + frame.height / 2

        let windowFrame = window.frame
        let screenHeight = NSScreen.main?.frame.height ?? 1080
        let contentHeight = window.contentView?.frame.height ?? windowFrame.height

        let screenX = windowFrame.origin.x + centerX
        let screenY = screenHeight - (windowFrame.origin.y + contentHeight - centerY)

        return CGPoint(x: screenX, y: screenY)
    }

    /// Find the window containing a point in view coordinates
    public static func findWindow(for point: CGPoint) -> NSWindow? {
        let visibleWindows = NSApplication.shared.windows.filter { $0.isVisible && $0.frame.width > 0 }

        for window in visibleWindows {
            let contentFrame = window.contentView?.frame ?? window.frame
            if point.x <= contentFrame.width && point.y <= contentFrame.height {
                return window
            }
        }

        return NSApplication.shared.mainWindow ?? visibleWindows.first
    }
}

// MARK: - Unified Input Interface

/// Unified interface for macOS input simulation
@MainActor
public struct AwareMacOSInput {
    /// Simulate a click at a screen point
    public static func click(at point: CGPoint) async -> Bool {
        await AwareMacOSMouse.click(at: point)
    }

    /// Simulate a long press at a screen point
    public static func longPress(at point: CGPoint, duration: TimeInterval = 0.5) async -> Bool {
        await AwareMacOSMouse.longPress(at: point, duration: duration)
    }

    /// Type a string character by character
    public static func type(_ text: String) async {
        for char in text {
            guard let (keyCode, needsShift) = AwareMacOSKeyboard.keyCodeForCharacter(char) else {
                // Use Unicode input for special characters
                let unicodeEvents = AwareMacOSKeyboard.createUnicodeKeyEvents(for: char)
                for event in unicodeEvents {
                    event.post(tap: .cghidEventTap)
                    try? await Task.sleep(nanoseconds: 10_000_000) // 10ms between events
                }
                continue
            }

            guard let keyDown = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: true),
                  let keyUp = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: false) else {
                continue
            }

            if needsShift {
                keyDown.flags = .maskShift
                keyUp.flags = .maskShift
            }

            keyDown.post(tap: .cghidEventTap)
            try? await Task.sleep(nanoseconds: 20_000_000) // 20ms
            keyUp.post(tap: .cghidEventTap)
            try? await Task.sleep(nanoseconds: 10_000_000) // 10ms between characters
        }
    }
}

#endif // os(macOS)
