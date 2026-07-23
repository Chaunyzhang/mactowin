import SwiftUI
import AppKit

@main
struct mactowinApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @StateObject private var settings = SettingsStore.shared

    var body: some Scene {
        MenuBarExtra {
            MenuBarView()
                .environmentObject(settings)
        } label: {
            Image(systemName: "doc.on.clipboard")
                .opacity(settings.appEnabled ? 1 : 0.35)
        }
        .menuBarExtraStyle(.menu)

        Settings {
            SettingsView()
                .environmentObject(settings)
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate {
    private let serviceProvider = NewTextFileServiceProvider()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        NSApp.servicesProvider = serviceProvider

        ClipboardMonitor.shared.start()

        HotkeyManager.shared.handler = { action in
            switch action {
            case .saveImage:
                ImagePasteSaver.shared.saveClipboardImage()
            case .toggleHistory:
                HistoryPanelController.shared.toggle()
            case .copyFinderPath:
                CopyPathAction.copyCurrentFinderPath()
            }
        }
        HotkeyManager.shared.reregister()

        InputMapper.shared.syncWithSettings(); ScrollReverser.shared.syncWithSettings()
        VerificationCodeWatcher.shared.syncWithSettings()
    }
}
