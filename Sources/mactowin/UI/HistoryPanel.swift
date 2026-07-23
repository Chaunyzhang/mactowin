import AppKit
import SwiftUI

// MARK: - 历史面板窗口管理

final class HistoryPanelController: NSObject {
    static let shared = HistoryPanelController()

    private var panel: NSPanel?

    func toggle() {
        if let panel, panel.isVisible {
            close()
        } else {
            show()
        }
    }

    func show() {
        let view = HistoryView { [weak self] item in
            ClipboardHistoryStore.shared.copyToPasteboard(item)
            self?.close()
        }
        let hosting = NSHostingController(rootView: view)

        let panel = NSPanel(contentViewController: hosting)
        panel.styleMask = [.titled, .closable, .nonactivatingPanel]
        panel.title = NSLocalizedString("剪贴板历史", comment: "历史面板标题")
        panel.titlebarAppearsTransparent = true
        panel.isFloatingPanel = true
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        panel.isReleasedWhenClosed = false
        panel.setContentSize(NSSize(width: 380, height: 420))

        // 显示在鼠标附近
        let mouse = NSEvent.mouseLocation
        let origin = NSPoint(x: mouse.x - 190, y: mouse.y - 440)
        panel.setFrameOrigin(origin)
        if let screen = NSScreen.main {
            let clipped = panel.frame.intersection(screen.visibleFrame.insetBy(dx: 8, dy: 8))
            panel.setFrame(clipped, display: false)
        }

        panel.orderFront(nil)
        self.panel = panel
    }

    func close() {
        panel?.close()
        panel = nil
    }
}

// MARK: - 历史列表视图

struct HistoryView: View {
    @ObservedObject private var store = ClipboardHistoryStore.shared
    var onSelect: (ClipboardItem) -> Void

    var body: some View {
        VStack(spacing: 0) {
            if store.items.isEmpty {
                Spacer()
                Text("暂无剪贴板记录\n复制任意内容后再按 ⌘⇧V")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 2) {
                        ForEach(store.items) { item in
                            Button {
                                onSelect(item)
                            } label: {
                                HistoryRow(item: item)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(6)
                }
                Divider()
                HStack {
                    Text("\(store.items.count) 条记录 · 点击复制到剪贴板")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("清空") { store.clear() }
                        .font(.caption)
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 380, height: 420)
    }
}

private struct HistoryRow: View {
    let item: ClipboardItem
    @State private var hovering = false

    var body: some View {
        HStack(spacing: 10) {
            icon
                .frame(width: 28, height: 28)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .lineLimit(2)
                    .truncationMode(.tail)
                    .font(.system(size: 12))
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(hovering ? Color.accentColor.opacity(0.15) : Color.clear)
        .cornerRadius(6)
        .onHover { hovering = $0 }
    }

    @ViewBuilder
    private var icon: some View {
        switch item.content {
        case .text:
            Image(systemName: "doc.plaintext")
                .font(.title3)
        case .image(let data):
            if let img = NSImage(data: data) {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipped()
                    .cornerRadius(4)
            } else {
                Image(systemName: "photo")
                    .font(.title3)
            }
        case .files:
            Image(systemName: "doc.on.doc")
                .font(.title3)
        }
    }

    private var title: String {
        switch item.content {
        case .text(let s):
            return s.components(separatedBy: .newlines).joined(separator: " ⏎ ")
        case .image:
            return "图片"
        case .files(let urls):
            return urls.map { $0.lastPathComponent }.joined(separator: ", ")
        }
    }

    private var subtitle: String {
        let time = item.date.formatted(date: .omitted, time: .shortened)
        switch item.content {
        case .text(let s):
            return "\(time) · \(s.count) 个字符"
        case .image(let data):
            return "\(time) · \(data.count / 1024) KB"
        case .files(let urls):
            return "\(time) · \(urls.count) 个项目"
        }
    }
}
