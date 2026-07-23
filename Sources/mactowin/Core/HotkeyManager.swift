import AppKit
import Carbon.HIToolbox

/// 基于 Carbon RegisterEventHotKey 的全局热键（无需辅助功能权限）
/// 快捷键组合可在设置中自定义，存储于 SettingsStore.hotkeyBindings
final class HotkeyManager {
    static let shared = HotkeyManager()

    var handler: ((HotkeyAction) -> Void)?

    private var refs: [EventHotKeyRef?] = []
    private var handlerInstalled = false

    /// 按当前设置重新注册全部热键
    func reregister() {
        for ref in refs {
            if let ref { UnregisterEventHotKey(ref) }
        }
        refs = []
        installHandlerIfNeeded()

        let s = SettingsStore.shared
        guard s.appEnabled else { return }
        if s.imageSaverEnabled {
            register(action: .saveImage, hotkey: s.hotkey(for: .saveImage))
        }
        if s.historyEnabled {
            register(action: .toggleHistory, hotkey: s.hotkey(for: .toggleHistory))
        }
        if s.copyPathEnabled {
            register(action: .copyFinderPath, hotkey: s.hotkey(for: .copyFinderPath))
        }
    }

    private func installHandlerIfNeeded() {
        guard !handlerInstalled else { return }
        var eventType = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        InstallEventHandler(GetEventDispatcherTarget(), { _, event, _ -> OSStatus in
            guard let event else { return OSStatus(eventNotHandledErr) }
            var hotKeyID = EventHotKeyID()
            let err = GetEventParameter(
                event,
                EventParamName(kEventParamDirectObject),
                EventParamType(typeEventHotKeyID),
                nil,
                MemoryLayout<EventHotKeyID>.size,
                nil,
                &hotKeyID
            )
            guard err == noErr, let action = HotkeyAction(rawValue: hotKeyID.id) else {
                return OSStatus(eventNotHandledErr)
            }
            DispatchQueue.main.async {
                HotkeyManager.shared.handler?(action)
            }
            return noErr
        }, 1, &eventType, nil, nil)
        handlerInstalled = true
    }

    private func register(action: HotkeyAction, hotkey: Hotkey) {
        // 'M2Wn'
        let signature = OSType(0x4D32576E)
        let hotKeyID = EventHotKeyID(signature: signature, id: action.rawValue)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            hotkey.keyCode, hotkey.carbonModifiers, hotKeyID,
            GetEventDispatcherTarget(), 0, &ref
        )
        if status != noErr {
            NSLog("mactowin: 热键注册失败（可能被占用）: \(hotkey.display) action=\(action.rawValue) status=\(status)")
        }
        refs.append(ref)
    }
}
