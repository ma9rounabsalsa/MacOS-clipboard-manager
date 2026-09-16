import Foundation
import AppKit
import Combine

final class ClipboardMonitor: ObservableObject {
    @Published var items: [ClipboardItem] = []
    @Published var searchQuery: String = ""

    private var timer: Timer?
    private var lastChangeCount: Int = NSPasteboard.general.changeCount
    private let maxUnpinnedItems = 100
    private let saveURL: URL

    var filteredItems: [ClipboardItem] {
        let base: [ClipboardItem]
        if searchQuery.isEmpty {
            base = items
        } else {
            base = items.filter { $0.text.localizedCaseInsensitiveContains(searchQuery) }
        }
        return base.sorted { lhs, rhs in
            if lhs.isPinned != rhs.isPinned {
                return lhs.isPinned && !rhs.isPinned
            }
            return lhs.timestamp > rhs.timestamp
        }
    }

    init() {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("ClipboardManager", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        self.saveURL = dir.appendingPathComponent("history.json")

        loadHistory()
        startMonitoring()
    }

    func startMonitoring() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkPasteboard()
        }
    }

    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }

    private func checkPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else { return }
        lastChangeCount = pasteboard.changeCount

        if let imageData = pasteboard.data(forType: .tiff),
           let image = NSImage(data: imageData),
           let pngData = image.pngData() {
            addItem(text: "Image (\(Int(image.size.width))×\(Int(image.size.height)))",
                    type: .image,
                    imageData: pngData)
            return
        }

        guard let text = pasteboard.string(forType: .string),
              !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }


        if let mostRecent = items.first, mostRecent.text == text, mostRecent.type != .image {
            return
        }

        let type = ClipboardItem.detectType(from: text)
        addItem(text: text, type: type)
    }

    private func addItem(text: String, type: ClipboardContentType, imageData: Data? = nil) {
        let item = ClipboardItem(text: text, type: type, imageData: imageData)
        DispatchQueue.main.async {
            self.items.insert(item, at: 0)
            self.trimHistory()
            self.saveHistory()
        }
    }

    private func trimHistory() {
        let unpinned = items.filter { !$0.isPinned }
        if unpinned.count > maxUnpinnedItems {
            let toRemove = Set(unpinned.suffix(unpinned.count - maxUnpinnedItems).map { $0.id })
            items.removeAll { toRemove.contains($0.id) }
        }
    }

    func copyToClipboard(_ item: ClipboardItem) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()

        if item.type == .image, let image = item.nsImage {
            pasteboard.writeObjects([image])
        } else {
            pasteboard.setString(item.text, forType: .string)
        }
        lastChangeCount = pasteboard.changeCount
    }

    func togglePin(_ item: ClipboardItem) {
        guard let index = items.firstIndex(where: { $0.id == item.id }) else { return }
        items[index].isPinned.toggle()
        saveHistory()
    }

    func delete(_ item: ClipboardItem) {
        items.removeAll { $0.id == item.id }
        saveHistory()
    }

    func clearHistory(keepPinned: Bool = true) {
        if keepPinned {
            items.removeAll { !$0.isPinned }
        } else {
            items.removeAll()
        }
        saveHistory()
    }

    private func saveHistory() {
        let toSave = items.filter { $0.type != .image || $0.isPinned }
        if let data = try? JSONEncoder().encode(toSave) {
            try? data.write(to: saveURL)
        }
    }

    private func loadHistory() {
        guard let data = try? Data(contentsOf: saveURL),
              let decoded = try? JSONDecoder().decode([ClipboardItem].self, from: data) else { return }
        items = decoded
    }
}

extension NSImage {
    func pngData() -> Data? {
        guard let tiffData = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData) else { return nil }
        return bitmap.representation(using: .png, properties: [:])
    }
}
