import SwiftUI
import ServiceManagement

// MARK: - 系统 defaults 开关行

/// 读写系统 defaults 的开关；inverted=true 表示「开」对应写 false（如关闭确认弹窗类）
struct DefaultsToggleRow: View {
    let title: LocalizedStringKey
    let domain: String
    let key: String
    var inverted = false
    var restartFinder = false

    @State private var on: Bool

    init(title: LocalizedStringKey, domain: String, key: String, inverted: Bool = false, restartFinder: Bool = false) {
        self.title = title
        self.domain = domain
        self.key = key
        self.inverted = inverted
        self.restartFinder = restartFinder
        let raw = SystemDefaults.bool(domain, key)
        _on = State(initialValue: inverted ? !raw : raw)
    }

    var body: some View {
        Toggle(title, isOn: $on)
            .onChange(of: on) {
                SystemDefaults.setBool(domain, key, inverted ? !on : on)
                if restartFinder { SystemDefaults.restartFinder() }
            }
    }
}

// MARK: - 设置主界面（Tab 分页）

struct SettingsView: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        TabView {
            GeneralSettingsTab()
                .tabItem { Label("通用", systemImage: "gearshape") }
            FeaturesSettingsTab()
                .tabItem { Label("功能", systemImage: "command.square") }
            FinderSettingsTab()
                .tabItem { Label("访达", systemImage: "folder") }
            InputSettingsTab()
                .tabItem { Label("键盘鼠标", systemImage: "keyboard") }
            WindowSettingsTab()
                .tabItem { Label("窗口", systemImage: "macwindow") }
        }
        .frame(width: 560, height: 480)
        .environmentObject(settings)
    }
}

// MARK: - 通用

private struct GeneralSettingsTab: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var axTrusted = InputMapper.accessibilityGranted
    private let pollTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        Form {
            Section("权限") {
                HStack(spacing: 8) {
                    Circle()
                        .fill(axTrusted ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(axTrusted ? "辅助功能：已授权" : "辅助功能：未授权")
                    Spacer()
                    if !axTrusted {
                        Button("打开系统设置授权") {
                            InputMapper.requestAccessibility()
                        }
                    }
                }
                Text("按键映射、窗口管理、鼠标滚轮反向需要此权限；授权后立即生效，无需重启。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("通用") {
                Toggle("登录时启动", isOn: $settings.launchAtLogin)
            }

            Section("关于") {
                HStack {
                    Text("mactowin")
                    Spacer()
                    Text("Make macOS behave like Windows.")
                        .foregroundStyle(.secondary)
                }
                Text("Windows 迁移者的一站式兼容层。重度窗口切换用户建议搭配免费开源的 AltTab。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .onReceive(pollTimer) { _ in
            let trusted = InputMapper.accessibilityGranted
            if trusted != axTrusted {
                axTrusted = trusted
                InputMapper.shared.syncWithSettings()
                ScrollReverser.shared.syncWithSettings()
            }
            // FDA 可能已在系统设置里授予，定期尝试启动短信监听
            VerificationCodeWatcher.shared.syncWithSettings()
        }
    }
}

// MARK: - 功能（快捷键功能 + 键位自定义）

private struct FeaturesSettingsTab: View {
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        Form {
            Section("功能开关与快捷键（点击右侧按钮后直接按新组合键即可修改）") {
                HStack {
                    Toggle("图片粘贴保存为 PNG", isOn: $settings.imageSaverEnabled)
                    Spacer()
                    HotkeyRecorderView(action: .saveImage)
                }
                HStack {
                    Toggle("剪贴板历史", isOn: $settings.historyEnabled)
                    Spacer()
                    HotkeyRecorderView(action: .toggleHistory)
                }
                HStack {
                    Toggle("复制当前位置路径", isOn: $settings.copyPathEnabled)
                    Spacer()
                    HotkeyRecorderView(action: .copyFinderPath)
                }
                Toggle("新建文本文件　（菜单栏按钮 + Finder 服务菜单）", isOn: $settings.newTextFileEnabled)
                HStack {
                    Spacer()
                    Button("快捷键全部恢复默认") { settings.resetHotkeys() }
                        .font(.caption)
                }
            }

            Section("图片粘贴保存") {
                Picker("保存位置", selection: $settings.imageSaveLocation) {
                    ForEach(SettingsStore.ImageSaveLocation.allCases) { location in
                        Text(LocalizedStringKey(location.title)).tag(location)
                    }
                }
                Toggle("保存后把新文件放入剪贴板（方便立即粘贴到别处）", isOn: $settings.copyFileAfterImageSave)
            }

            Section("剪贴板历史") {
                Stepper("保留最近 \(settings.historyLimit) 条", value: $settings.historyLimit, in: 5...100)
            }

            Section("短信验证码") {
                Toggle("收到验证码短信时自动复制到剪贴板", isOn: $settings.smsCodeEnabled)
                HStack(spacing: 8) {
                    Circle()
                        .fill(VerificationCodeWatcher.messagesDBReadable ? Color.green : Color.red)
                        .frame(width: 8, height: 8)
                    Text(VerificationCodeWatcher.messagesDBReadable ? "完全磁盘访问：已授权" : "完全磁盘访问：未授权")
                    Spacer()
                    if !VerificationCodeWatcher.messagesDBReadable {
                        Button("去授权") {
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
                        }
                    }
                }
                Text("通过读取「信息」App 的本地短信数据库实现，需要完全磁盘访问权限；授权后重新打开本设置页生效。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - 访达

private struct FinderSettingsTab: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var searchCurrentFolder =
        SystemDefaults.string("com.apple.finder", "FXDefaultSearchScope") == "SCcf"

    var body: some View {
        Form {
            Section("访达按键（Windows 习惯）") {
                Toggle("Windows 风格剪切粘贴　（⌘X 剪切、⌘V 移动）", isOn: $settings.windowsCutPasteEnabled)
                Toggle("Delete (⌫) 返回上级目录", isOn: $settings.backspaceGoesUpEnabled)
                Toggle("Enter 打开 / F2 改名", isOn: $settings.enterOpensEnabled)
                Toggle("fn+Delete 删除文件", isOn: $settings.forwardDeleteEnabled)
                Toggle("⌘L 输入路径直达（地址栏）", isOn: $settings.cmdLAddressBarEnabled)
                Toggle("⌥Enter 显示简介（Windows 的 Alt+Enter 属性）", isOn: $settings.altEnterInfoEnabled)
            }

            Section("访达增强（切换后自动重启访达生效）") {
                DefaultsToggleRow(title: "路径栏（窗口底部显示完整路径）",
                                  domain: "com.apple.finder", key: "ShowPathbar", restartFinder: true)
                DefaultsToggleRow(title: "状态栏（项目数量和剩余空间）",
                                  domain: "com.apple.finder", key: "ShowStatusBar", restartFinder: true)
                DefaultsToggleRow(title: "按名称排序时文件夹置顶",
                                  domain: "com.apple.finder", key: "_FXSortFoldersFirst", restartFinder: true)
                Toggle("搜索默认当前文件夹（而不是整台 Mac）", isOn: $searchCurrentFolder)
                    .onChange(of: searchCurrentFolder) {
                        SystemDefaults.setString("com.apple.finder", "FXDefaultSearchScope",
                                                 searchCurrentFolder ? "SCcf" : "SCev")
                        SystemDefaults.restartFinder()
                    }
                DefaultsToggleRow(title: "显示所有文件扩展名",
                                  domain: "NSGlobalDomain", key: "AppleShowAllExtensions", restartFinder: true)
                DefaultsToggleRow(title: "清倒废纸篓不再确认",
                                  domain: "com.apple.finder", key: "WarnOnEmptyTrash", inverted: true, restartFinder: true)
                DefaultsToggleRow(title: "修改扩展名不再警告",
                                  domain: "com.apple.finder", key: "FXEnableExtensionChangeWarning", inverted: true, restartFinder: true)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - 键盘鼠标

private struct InputSettingsTab: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var mouseNoAccel =
        (SystemDefaults.string("NSGlobalDomain", "com.apple.mouse.scaling").flatMap(Double.init) ?? 1) <= 0

    var body: some View {
        Form {
            Section("键盘习惯") {
                Toggle("Home/End 跳到行首/行尾（而不是文档开头/结尾）", isOn: $settings.homeEndEnabled)
                Toggle("Ctrl 兼容　（Ctrl+C/V/X/Z/A/S 等按 Windows 习惯生效，终端除外）", isOn: $settings.ctrlCompatEnabled)
                DefaultsToggleRow(
                    title: "F1-F12 默认作为标准功能键（按 fn 才是亮度音量）",
                    domain: "NSGlobalDomain",
                    key: "com.apple.keyboard.fnState"
                )
            }

            Section("鼠标") {
                Toggle("鼠标滚轮方向按 Windows 习惯（触控板保持自然不受影响）", isOn: $settings.mouseScrollReversedEnabled)
                Toggle("关闭鼠标加速度（重新登录后完全生效）", isOn: $mouseNoAccel)
                    .onChange(of: mouseNoAccel) {
                        SystemDefaults.setFloat("NSGlobalDomain", "com.apple.mouse.scaling",
                                                mouseNoAccel ? -1 : 1)
                    }
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - 窗口

private struct WindowSettingsTab: View {
    @EnvironmentObject private var settings: SettingsStore
    @State private var doubleClickMinimize =
        SystemDefaults.string("NSGlobalDomain", "AppleActionOnDoubleClick") == "Minimize"

    var body: some View {
        Form {
            Section("窗口管理（Windows 习惯）") {
                Toggle("⌃⌥←/→ 左右半屏、⌃⌥↑ 最大化、⌃⌥↓ 最小化", isOn: $settings.windowSnappingEnabled)
                Toggle("双击标题栏最小化（而不是缩放）", isOn: $doubleClickMinimize)
                    .onChange(of: doubleClickMinimize) {
                        SystemDefaults.setString("NSGlobalDomain", "AppleActionOnDoubleClick",
                                                 doubleClickMinimize ? "Minimize" : "Maximize")
                    }
            }

            Section("说明") {
                Text("最大化是「填充当前屏幕」，不会进入 macOS 全屏空间。需要窗口级 ⌘Tab 切换器的话，推荐搭配免费开源的 AltTab。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
    }
}

// MARK: - 登录启动

enum LaunchAtLogin {
    static func apply(_ enabled: Bool) {
        // 只有打包成 .app 后才支持
        guard Bundle.main.bundleURL.pathExtension == "app" else { return }
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            NSLog("mactowin: 登录项设置失败: \(error.localizedDescription)")
        }
    }
}
