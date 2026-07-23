<div align="center">

<img src="Resources/AppIcon.png" width="96" />

# mactowin

### 🌉 Make macOS behave like Windows.
### 让 macOS 用起来像 Windows 一样顺手

<sub>Windows 迁移者的一站式兼容层 · 不用装 7 个 App</sub>
<sub>An all-in-one compatibility layer for Windows switchers</sub>

[![Release](https://img.shields.io/github/v/release/Chaunyzhang/mactowin?style=flat-square&color=blueviolet)](https://github.com/Chaunyzhang/mactowin/releases)
[![Platform](https://img.shields.io/badge/platform-macOS%2014%2B-black?style=flat-square&logo=apple)](https://github.com/Chaunyzhang/mactowin)
[![License](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)
[![Swift](https://img.shields.io/badge/Swift-6-orange?style=flat-square&logo=swift)](https://github.com/Chaunyzhang/mactowin)

</div>

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/2728/512.gif" width="28" /> 功能 · Features

> 每个功能都有独立开关 + 全局总开关，快捷键可自定义。
> Every feature has its own toggle, a master switch, and customizable hotkeys.

| | 功能 · Feature | 说明 · Description |
|:---:|---|---|
| <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4f7/512.gif" width="32" /> | **图片粘贴保存**<br/>**Paste Image as File** | 剪贴板里的图片按 `⌥⌘V` 直接存成 PNG，位置跟随鼠标点选；终端里按时自动把路径填进命令行<br/>Press `⌥⌘V` to save clipboard images as PNG where you clicked; in Terminal the file path is typed for you |
| <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4da/512.gif" width="32" /> | **剪贴板历史**<br/>**Clipboard History** | 类 Win+V 的历史面板，文本 / 图片 / 文件，点击复制<br/>A Win+V-style history panel for text, images and files |
| <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/2702/512.gif" width="32" /> | **真·剪切粘贴**<br/>**Real Cut & Paste** | 访达里 `⌘X` 剪切、`⌘V` **移动**文件，Windows 语义<br/>`⌘X` cuts, `⌘V` actually **moves** files in Finder |
| <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/26a1/512.gif" width="32" /> | **访达按键 Windows 化**<br/>**Windows-style Finder Keys** | `⌫` 返回上级 · `Enter` 打开 · `F2` 改名 · `fn+Delete` 删除 · `⌘L` 地址栏 · `⌥Enter` 显示简介<br/>`⌫` go up · `Enter` open · `F2` rename · `fn+Delete` delete · `⌘L` path bar · `⌥Enter` get info |
| <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4bb/512.gif" width="32" /> | **键盘习惯兼容**<br/>**Keyboard Habits** | Home/End 跳行首行尾；Ctrl+C/V/X/Z/A/S 直接生效（终端除外）；F1-F12 标准功能键<br/>Home/End to line start/end; Ctrl+C/V/X/Z/A/S work as on Windows (except Terminal); standard F-keys |
| <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f3af/512.gif" width="32" /> | **窗口分屏**<br/>**Window Snapping** | `⌃⌥←/→` 左右半屏 · `⌃⌥↑` 真最大化 · `⌃⌥↓` 最小化 · 双击标题栏最小化<br/>`⌃⌥←/→` snap halves · `⌃⌥↑` maximize (not fullscreen) · `⌃⌥↓` minimize |
| <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f5d1/512.gif" width="32" /> | **鼠标按 Windows 来**<br/>**Windows-style Mouse** | 滚轮方向独立反转（触控板不受影响）· 可选关闭鼠标加速度<br/>Independent scroll reversal (trackpad unaffected) · optional acceleration off |
| <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f4ac/512.gif" width="32" /> | **验证码自动复制**<br/>**Auto-Copy SMS Codes** | 收到验证码短信 → 自动进剪贴板，直接 `⌘V`，全程零操作<br/>Verification SMS arrives → code is already on your clipboard. Just `⌘V` |
| <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f6e0/512.gif" width="32" /> | **访达增强 ×7**<br/>**Finder Tweaks ×7** | 路径栏 · 状态栏 · 文件夹置顶 · 搜索当前文件夹 · 显示扩展名 · 关确认弹窗<br/>Path bar · status bar · folders on top · search current folder · show extensions · fewer alerts |
| 🌐 | **中英双语**<br/>**Bilingual UI** | 界面跟随系统语言自动切换<br/>UI follows your system language automatically |

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f680/512.gif" width="28" /> 安装 · Install

**1️⃣** 下载 [最新 Release](https://github.com/Chaunyzhang/mactowin/releases/latest)，把 mactowin 拖入「应用程序」
Download the [latest release](https://github.com/Chaunyzhang/mactowin/releases/latest) and drag mactowin into Applications

**2️⃣** 首次打开会被 Gatekeeper 拦截（开源软件未购买 Apple 签名），放行一次即可：
First launch is blocked by Gatekeeper (unsigned open-source build). Allow it once:

> **系统设置 → 隐私与安全性 → 最下方「仍要打开」**
> **System Settings → Privacy & Security → "Open Anyway"**

已经拖进「应用程序」后，也可以用一行命令代替上面的手动放行（macOS 自带命令，无需安装任何东西）：
Already dragged into Applications? You can skip the manual step with this built-in macOS command instead:

```bash
xattr -dr com.apple.quarantine /Applications/mactowin.app
```

> 💡 使用稳定的自签名证书打包：版本更新后辅助功能 / 完全磁盘访问授权**不会失效**。
> Signed with a stable certificate: permissions survive updates, grant once and forget.

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/26a0/512.gif" width="28" /> 需要的权限 · Permissions

| 权限 · Permission | 用途 · Why |
|---|---|
| **辅助功能** Accessibility | 按键映射、窗口分屏、滚轮反向 · Key mapping, snapping, scroll reversal |
| **完全磁盘访问** Full Disk Access | 仅「验证码自动复制」需要（读取信息 App 本地数据库）· Only for SMS code auto-copy |
| **Finder 控制** Automation | 保存到当前文件夹、剪切粘贴等 · Save-to-current-folder, cut & paste |

---

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f6e0/512.gif" width="28" /> 自行构建 · Build from Source

```bash
git clone https://github.com/Chaunyzhang/mactowin.git && cd mactowin
./scripts/build_app.sh     # 产出 ~/Applications/mactowin.app
swift test                 # 单元测试
```

## <img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f44b/512.gif" width="28" /> 推荐搭配 · Pairs Well With

需要窗口级 `⌘Tab` 切换器？推荐免费开源的 [**AltTab**](https://github.com/lwouis/alt-tab-macos)，与 mactowin 互补。
Want a window-level `⌘Tab` switcher? Try the free & open-source [**AltTab**](https://github.com/lwouis/alt-tab-macos) — it complements mactowin perfectly.

---

<div align="center">

<sub>MIT License · © 2026 Chauny Zhang</sub>
<br/>
<img src="https://fonts.gstatic.com/s/e/notoemoji/latest/1f389/512.gif" width="24" /> <sub>如果这个工具帮到了你，欢迎点个 ⭐ Star</sub>
<br/>
<sub>If mactowin helps you, a ⭐ star means a lot</sub>

</div>
