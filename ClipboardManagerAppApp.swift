import SwiftUI
import AppKit
import Carbon.HIToolbox

@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra {
            ContentView()
                .environmentObject(appDelegate.monitor)
        } label: {
            Image(systemName: "doc.on.clipboard")
        }
        .menuBarExtraStyle(.window)
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    let monitor = ClipboardMonitor()
    private var hotKeyRef: EventHotKeyRef?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        registerGlobalHotKey()
    }

    // BROKEN DOSN'T WORKS ⌘⇧V NEED FIX
    private func registerGlobalHotKey() {
        let hotKeyID = EventHotKeyID(signature: OSType(0x434C4950), id: 1)
        let modifiers = UInt32(cmdKey | shiftKey)
        let keyCode = UInt32(kVK_ANSI_V)

        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, _ -> OSStatus in
            NotificationCenter.default.post(name: .clipboardHotKeyPressed, object: nil)
            return noErr
        }, 1, &eventType, nil, nil)

        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetApplicationEventTarget(), 0, &hotKeyRef)
    }
}

extension Notification.Name {
    static let clipboardHotKeyPressed = Notification.Name("clipboardHotKeyPressed")
}
