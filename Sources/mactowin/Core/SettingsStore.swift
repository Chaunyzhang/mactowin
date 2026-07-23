import Foundation

final class SettingsStore: ObservableObject {
    static let shared = SettingsStore()

    private let defaults = UserDefaults.standard

    enum ImageSaveLocation: String, CaseIterable, Identifiable {
        case finderWindow
        case desktop
        case downloads

        var id: String { rawValue }

        var title: String {
            switch self {
            case .finderWindow: return "跟随鼠标点选位置（点了桌面就存桌面）"
            case .desktop: return "桌面"
            case .downloads: return "下载"
            }
        }
    }

    @Published var imageSaverEnabled: Bool {
        didSet { defaults.set(imageSaverEnabled, forKey: Key.imageSaverEnabled); HotkeyManager.shared.reregister() }
    }
    @Published var historyEnabled: Bool {
        didSet { defaults.set(historyEnabled, forKey: Key.historyEnabled); HotkeyManager.shared.reregister() }
    }
    @Published var windowsCutPasteEnabled: Bool {
        didSet { defaults.set(windowsCutPasteEnabled, forKey: Key.windowsCutPasteEnabled); InputMapper.shared.syncWithSettings() }
    }
    @Published var backspaceGoesUpEnabled: Bool {
        didSet { defaults.set(backspaceGoesUpEnabled, forKey: Key.backspaceGoesUpEnabled); InputMapper.shared.syncWithSettings() }
    }
    @Published var copyPathEnabled: Bool {
        didSet { defaults.set(copyPathEnabled, forKey: Key.copyPathEnabled); HotkeyManager.shared.reregister() }
    }
    // Batch A · 访达按键
    @Published var enterOpensEnabled: Bool {
        didSet { defaults.set(enterOpensEnabled, forKey: Key.enterOpensEnabled); InputMapper.shared.syncWithSettings() }
    }
    @Published var forwardDeleteEnabled: Bool {
        didSet { defaults.set(forwardDeleteEnabled, forKey: Key.forwardDeleteEnabled); InputMapper.shared.syncWithSettings() }
    }
    @Published var cmdLAddressBarEnabled: Bool {
        didSet { defaults.set(cmdLAddressBarEnabled, forKey: Key.cmdLAddressBarEnabled); InputMapper.shared.syncWithSettings() }
    }
    @Published var altEnterInfoEnabled: Bool {
        didSet { defaults.set(altEnterInfoEnabled, forKey: Key.altEnterInfoEnabled); InputMapper.shared.syncWithSettings() }
    }
    // Batch B · 键盘习惯
    @Published var homeEndEnabled: Bool {
        didSet { defaults.set(homeEndEnabled, forKey: Key.homeEndEnabled); InputMapper.shared.syncWithSettings() }
    }
    @Published var ctrlCompatEnabled: Bool {
        didSet { defaults.set(ctrlCompatEnabled, forKey: Key.ctrlCompatEnabled); InputMapper.shared.syncWithSettings() }
    }
    // Batch C · 窗口管理
    @Published var windowSnappingEnabled: Bool {
        didSet { defaults.set(windowSnappingEnabled, forKey: Key.windowSnappingEnabled); InputMapper.shared.syncWithSettings() }
    }
    // Batch D · 鼠标
    @Published var mouseScrollReversedEnabled: Bool {
        didSet { defaults.set(mouseScrollReversedEnabled, forKey: Key.mouseScrollReversedEnabled); ScrollReverser.shared.syncWithSettings() }
    }
    @Published var newTextFileEnabled: Bool {
        didSet { defaults.set(newTextFileEnabled, forKey: Key.newTextFileEnabled) }
    }
    @Published var smsCodeEnabled: Bool {
        didSet { defaults.set(smsCodeEnabled, forKey: Key.smsCodeEnabled); VerificationCodeWatcher.shared.syncWithSettings() }
    }
    /// 自定义热键（空 = 全部默认），持久化逻辑见 Hotkey.swift 扩展
    @Published var hotkeyBindings: [HotkeyAction: Hotkey]
    @Published var copyFileAfterImageSave: Bool {
        didSet { defaults.set(copyFileAfterImageSave, forKey: Key.copyFileAfterImageSave) }
    }
    @Published var historyLimit: Int {
        didSet { defaults.set(historyLimit, forKey: Key.historyLimit) }
    }
    @Published var imageSaveLocation: ImageSaveLocation {
        didSet { defaults.set(imageSaveLocation.rawValue, forKey: Key.imageSaveLocation) }
    }
    @Published var launchAtLogin: Bool {
        didSet { defaults.set(launchAtLogin, forKey: Key.launchAtLogin); LaunchAtLogin.apply(launchAtLogin) }
    }
    /// 全局总开关：停用后所有功能（热键/按键映射/滚轮/剪贴板监听）都不生效
    @Published var appEnabled: Bool {
        didSet {
            defaults.set(appEnabled, forKey: Key.appEnabled)
            HotkeyManager.shared.reregister()
            InputMapper.shared.syncWithSettings()
            ScrollReverser.shared.syncWithSettings()
            VerificationCodeWatcher.shared.syncWithSettings()
        }
    }

    private enum Key {
        static let imageSaverEnabled = "imageSaverEnabled"
        static let historyEnabled = "historyEnabled"
        static let windowsCutPasteEnabled = "windowsCutPasteEnabled"
        static let backspaceGoesUpEnabled = "backspaceGoesUpEnabled"
        static let copyPathEnabled = "copyPathEnabled"
        static let enterOpensEnabled = "enterOpensEnabled"
        static let forwardDeleteEnabled = "forwardDeleteEnabled"
        static let cmdLAddressBarEnabled = "cmdLAddressBarEnabled"
        static let altEnterInfoEnabled = "altEnterInfoEnabled"
        static let homeEndEnabled = "homeEndEnabled"
        static let ctrlCompatEnabled = "ctrlCompatEnabled"
        static let windowSnappingEnabled = "windowSnappingEnabled"
        static let mouseScrollReversedEnabled = "mouseScrollReversedEnabled"
        static let newTextFileEnabled = "newTextFileEnabled"
        static let smsCodeEnabled = "smsCodeEnabled"
        static let copyFileAfterImageSave = "copyFileAfterImageSave"
        static let historyLimit = "historyLimit"
        static let imageSaveLocation = "imageSaveLocation"
        static let launchAtLogin = "launchAtLogin"
        static let appEnabled = "appEnabled"
    }

    private init() {
        defaults.register(defaults: [
            Key.imageSaverEnabled: true,
            Key.historyEnabled: true,
            Key.windowsCutPasteEnabled: true,
            Key.backspaceGoesUpEnabled: true,
            Key.copyPathEnabled: true,
            Key.enterOpensEnabled: true,
            Key.forwardDeleteEnabled: true,
            Key.cmdLAddressBarEnabled: true,
            Key.altEnterInfoEnabled: true,
            Key.homeEndEnabled: true,
            Key.ctrlCompatEnabled: true,
            Key.windowSnappingEnabled: true,
            Key.mouseScrollReversedEnabled: true,
            Key.newTextFileEnabled: true,
            Key.smsCodeEnabled: true,
            Key.copyFileAfterImageSave: true,
            Key.historyLimit: 20,
            Key.imageSaveLocation: ImageSaveLocation.finderWindow.rawValue,
            Key.launchAtLogin: false,
            Key.appEnabled: true,
        ])
        imageSaverEnabled = defaults.bool(forKey: Key.imageSaverEnabled)
        historyEnabled = defaults.bool(forKey: Key.historyEnabled)
        windowsCutPasteEnabled = defaults.bool(forKey: Key.windowsCutPasteEnabled)
        backspaceGoesUpEnabled = defaults.bool(forKey: Key.backspaceGoesUpEnabled)
        copyPathEnabled = defaults.bool(forKey: Key.copyPathEnabled)
        enterOpensEnabled = defaults.bool(forKey: Key.enterOpensEnabled)
        forwardDeleteEnabled = defaults.bool(forKey: Key.forwardDeleteEnabled)
        cmdLAddressBarEnabled = defaults.bool(forKey: Key.cmdLAddressBarEnabled)
        altEnterInfoEnabled = defaults.bool(forKey: Key.altEnterInfoEnabled)
        homeEndEnabled = defaults.bool(forKey: Key.homeEndEnabled)
        ctrlCompatEnabled = defaults.bool(forKey: Key.ctrlCompatEnabled)
        windowSnappingEnabled = defaults.bool(forKey: Key.windowSnappingEnabled)
        mouseScrollReversedEnabled = defaults.bool(forKey: Key.mouseScrollReversedEnabled)
        newTextFileEnabled = defaults.bool(forKey: Key.newTextFileEnabled)
        smsCodeEnabled = defaults.bool(forKey: Key.smsCodeEnabled)
        // 先给默认值，全部属性初始化完成后再加载
        hotkeyBindings = [:]
        copyFileAfterImageSave = defaults.bool(forKey: Key.copyFileAfterImageSave)
        historyLimit = max(5, defaults.integer(forKey: Key.historyLimit))
        imageSaveLocation = ImageSaveLocation(rawValue: defaults.string(forKey: Key.imageSaveLocation) ?? "") ?? .finderWindow
        launchAtLogin = defaults.bool(forKey: Key.launchAtLogin)
        appEnabled = defaults.bool(forKey: Key.appEnabled)
        hotkeyBindings = loadHotkeys()
    }
}
