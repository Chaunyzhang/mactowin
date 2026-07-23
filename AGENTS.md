# AGENTS.md — mactowin

## 项目

macOS 菜单栏 App（Swift + SwiftUI/AppKit），定位「Windows 用户迁移到 Mac 的行为兼容层」，**不是剪贴板管理器**。官网直发（不上 App Store），无沙盒。

## 结构

- SPM executable target（`swift-tools-version:6.0`，Swift 5 language mode），Xcode 直接打开 `Package.swift` 开发
- `Sources/mactowin/Core/` — 剪贴板监听、热键（Carbon）、Finder AppleScript 桥、CGEventTap 剪切粘贴、设置
- `Sources/mactowin/UI/` — MenuBarExtra、历史面板（NSPanel+SwiftUI）、设置窗口
- `Resources/Info.plist` + `AppIcon.icns` — 打包时由脚本拷入 bundle
- `scripts/build_app.sh` — 产出 `~/Applications/mactowin.app`（项目目录在 iCloud 同步的 Documents 里，会破坏签名，故输出到 ~/Applications）（优先用「mactowin Local Dev」自签名证书，保证 TCC 授权可持续；缺证书时退回 ad-hoc）
- `scripts/create_dev_cert.sh` — 生成本机自签名开发证书（一次性）
- `scripts/make_icon.sh` — 重新生成图标

## 构建与测试

```bash
swift build && swift test        # 必须全绿
./scripts/build_app.sh           # 打包
```

## 约定

- UI 文案以中文字面量为键，英文翻译必须同步加到 `Resources/en.lproj/Localizable.strings`（跟随系统语言自动切换）；避免字符串拼接/动态 String 传给 SwiftUI（会绕过本地化），用 `Text(LocalizedStringKey(...))`
- 代码注释用中文
- 全局热键用 Carbon `RegisterEventHotKey`（不需要权限）；改键/拦截用 `InputMapper` 的 `CGEventTap`（需辅助功能）
- 合成事件必须走 `Keyboard.post`（带 marker 标记），`InputMapper` 收到标记事件直接放行，防循环映射
- 鼠标滚轮反向在 `ScrollReverser`（独立 tap，只处理非连续滚动=鼠标，触控板不动）
- 系统级开关走 `SystemDefaults`（defaults CLI）；写 Finder 配置后要 `restartFinder()`
- 与 Finder 交互一律走 `FinderBridge`（NSAppleScript，后台线程执行，回调回主线程）
- 每个功能必须有独立开关（`SettingsStore`）
- 权限缺失时静默降级 + 设置页显示状态，不弹骚扰窗口
- 产品调研与路线图：`docs/research-macos-complaints.md`（Batch A-D 已全量实现）
- 分发签名/公证流程见 README「分发」一节
