import SwiftUI

/// 快捷键录制按钮：点击后按下新组合键即生效；Esc 取消；冲突时提示
struct HotkeyRecorderView: View {
    let action: HotkeyAction

    @EnvironmentObject private var settings: SettingsStore
    @State private var recording = false
    @State private var conflict = false
    @State private var monitor: Any?

    var body: some View {
        HStack(spacing: 6) {
            Button {
                recording ? stopRecording() : startRecording()
            } label: {
                Group {
                    if recording {
                        Text("按下快捷键…")
                    } else {
                        Text(settings.hotkey(for: action).display)
                    }
                }
                .font(.system(size: 12, design: .monospaced))
                .frame(minWidth: 64)
            }
            .buttonStyle(.bordered)
            .tint(recording ? .accentColor : nil)

            if conflict {
                Text("已被占用")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .onDisappear { stopRecording() }
    }

    private func startRecording() {
        conflict = false
        recording = true
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            // Esc 取消
            if event.keyCode == 53 {
                stopRecording()
                return nil
            }
            guard let hotkey = Hotkey(event: event) else {
                // 没按修饰键，继续等
                return nil
            }
            if settings.isHotkeyTaken(hotkey, byOtherThan: action) {
                conflict = true
                stopRecording()
                return nil
            }
            conflict = false
            settings.setHotkey(hotkey, for: action)
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        if let monitor {
            NSEvent.removeMonitor(monitor)
            self.monitor = nil
        }
        recording = false
    }
}
