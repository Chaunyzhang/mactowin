import SwiftUI

struct MenuBarView: View {
    @Environment(\.openSettings) private var openSettings
    @EnvironmentObject private var settings: SettingsStore

    var body: some View {
        // 全局总开关（针对整个 App，与下面各功能开关不冲突）
        Toggle("启用 mactowin", isOn: $settings.appEnabled)

        Divider()

        // 最近收到的短信验证码（常驻，直到下一条验证码替换）
        if let recent = VerificationCodeWatcher.shared.recentCode {
            Button("复制验证码 \(recent.code)") {
                VerificationCodeWatcher.shared.copyRecentToClipboard()
            }
            Divider()
        }

        // 各功能启用 / 停用
        Menu("功能开关") {
            Toggle("图片粘贴保存", isOn: $settings.imageSaverEnabled)
            Toggle("剪贴板历史", isOn: $settings.historyEnabled)
            Toggle("复制当前位置路径", isOn: $settings.copyPathEnabled)
            Toggle("新建文本文件", isOn: $settings.newTextFileEnabled)
            Toggle("验证码自动复制", isOn: $settings.smsCodeEnabled)

            Divider()

            Toggle("剪切粘贴（⌘X/⌘V）", isOn: $settings.windowsCutPasteEnabled)
            Toggle("⌫ 返回上级", isOn: $settings.backspaceGoesUpEnabled)
            Toggle("Enter 打开 / F2 改名", isOn: $settings.enterOpensEnabled)
            Toggle("fn+Delete 删除文件", isOn: $settings.forwardDeleteEnabled)
            Toggle("⌘L 地址栏", isOn: $settings.cmdLAddressBarEnabled)
            Toggle("⌥Enter 显示简介", isOn: $settings.altEnterInfoEnabled)

            Divider()

            Toggle("Home/End 行首行尾", isOn: $settings.homeEndEnabled)
            Toggle("Ctrl 兼容", isOn: $settings.ctrlCompatEnabled)
            Toggle("窗口分屏（⌃⌥方向键）", isOn: $settings.windowSnappingEnabled)
            Toggle("鼠标滚轮 Windows 方向", isOn: $settings.mouseScrollReversedEnabled)
        }
        .disabled(!settings.appEnabled)

        Divider()

        Button("设置…") {
            NSApp.activate(ignoringOtherApps: true)
            openSettings()
        }

        Divider()

        Button("退出 mactowin") {
            NSApp.terminate(nil)
        }
    }
}
