import Foundation
import SwiftUI
import AppKit

enum ClipboardContentType: String, Codable {
    case text
    case url
    case color
    case image
}

struct ClipboardItem: Identifiable, Codable, Equatable {
    let id: UUID
    var text: String
    var type: ClipboardContentType
    var timestamp: Date
    var isPinned: Bool
    var imageData: Data?

    init(text: String, type: ClipboardContentType, imageData: Data? = nil, isPinned: Bool = false) {
        self.id = UUID()
        self.text = text
        self.type = type
        self.timestamp = Date()
        self.isPinned = isPinned
        self.imageData = imageData
    }

    // Automatically detects the content type from the text
    static func detectType(from string: String) -> ClipboardContentType {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)

        if let url = URL(string: trimmed), url.scheme != nil, url.host != nil {
            return .url
        }

        if isHexColor(trimmed) {
            return .color
        }

        return .text
    }

    static func isHexColor(_ string: String) -> Bool {
        var s = string
        if s.hasPrefix("#") { s.removeFirst() }
        guard s.count == 6 || s.count == 3 else { return false }
        return s.allSatisfy { $0.isHexDigit }
    }

    var swiftUIColor: Color? {
        guard type == .color else { return nil }
        var hex = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }

        if hex.count == 3 {
            hex = hex.map { "\($0)\($0)" }.joined()
        }

        guard hex.count == 6, let intVal = Int(hex, radix: 16) else { return nil }
        let r = Double((intVal >> 16) & 0xFF) / 255
        let g = Double((intVal >> 8) & 0xFF) / 255
        let b = Double(intVal & 0xFF) / 255
        return Color(red: r, green: g, blue: b)
    }

    var nsImage: NSImage? {
        guard let data = imageData else { return nil }
        return NSImage(data: data)
    }

    var relativeTime: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .abbreviated
        return formatter.localizedString(for: timestamp, relativeTo: Date())
    }

    var previewText: String {
        let cleaned = text.replacingOccurrences(of: "\n", with: " ")
        if cleaned.count > 80 {
            return String(cleaned.prefix(80)) + "…"
        }
        return cleaned
    }
}
