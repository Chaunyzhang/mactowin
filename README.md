# mactowin

> Make macOS behave like Windows.
> Windows 迁移者的一站式兼容层 —— 不用装 7 个 App。

把 macOS 上对 Windows 用户最反人类的地方，一个个补齐。不是又一个剪贴板管理器。

## 功能

### 快捷键功能（可在设置中自定义键位）

| 功能 | 默认快捷键 | 说明 |
|---|---|---|
| 🖼️ 图片粘贴保存 | `⌥⌘V` | 剪贴板图片存为 PNG，位置跟随鼠标点选（点了桌面就存桌面）；终端里按时自动把路径填进命令行 |
| 📋 剪贴板历史 | `⌘⇧V` | 类似 Windows 的 Win+V，文本/图片/文件，点击复制 |
| 📂 复制当前位置路径 | `⌃⌥C` | 复制当前 Finder 窗口/桌面位置的路径（与系统 ⌥⌘C 复制选中项互补） |
| 📄 新建文本文件 | 右键 → 服务 | `mactowin: 在此新建文本文件`，或从菜单栏图标触发 |

### 访达按键（Windows 习惯，各自独立开关）

| 按键 | 行为 |
|---|---|
| `⌘X` / `⌘V` | 真正的剪切 → 移动 |
| `⌫` | 返回上级目录（特殊视图里打开选中文件所在文件夹） |
| `Enter` / `F2` | 打开 / 改名（Windows 语义） |
| `fn+Delete` | 删除文件（⌘⌫） |
| `⌘L` | 输入路径直达（地址栏） |
| `⌥Enter` | 显示简介（Windows 的 Alt+Enter 属性） |

### 键盘习惯

- Home/End → 行首/行尾（仅文本焦点生效，访达/终端除外）
- Ctrl 兼容：Ctrl+C/V/X/Z/A/S/Y/W/T/F 按 Windows 习惯生效（终端除外）
- F1-F12 默认标准功能键开关

### 窗口管理

- `⌃⌥←/→` 左右半屏、`⌃⌥↑` 最大化（填充屏幕，非全屏）、`⌃⌥↓` 最小化
- 双击标题栏最小化开关

### 鼠标

- 鼠标滚轮方向按 Windows 习惯（触控板保持自然，互不影响；系统已关自然滚动时自动不翻转）
- 关闭鼠标加速度开关

### 访达增强（写系统配置，自动重启访达生效）

路径栏 / 状态栏 / 文件夹置顶 / 搜索默认当前文件夹 / 显示所有扩展名 / 清倒废纸篓不确认 / 改扩展名不警告

每个功能都可以在设置里单独开关。界面跟随系统语言（中文/English），英文系统下自动显示英文。

## 运行

```bash
./scripts/create_dev_cert.sh   # 生成本机开发证书（只需一次，否则 TCC 授权每次都弹）
./scripts/make_icon.sh         # 生成图标（只需一次）
./scripts/build_app.sh         # 构建 ~/Applications/mactowin.app（自动用开发证书签名）
open ~/Applications/mactowin.app
```

首次使用会按需弹出系统授权：

- **辅助功能**：按键映射、窗口管理、滚轮反向需要；设置页有状态指示和跳转按钮
- **Finder 控制（Apple Events）**：图片保存到当前文件夹、剪切粘贴等用到

## 推荐搭配

mactowin 不做窗口级 ⌘Tab 替代（那是 [AltTab](https://github.com/lwouis/alt-tab-macos) 的领域，免费开源且优秀），重度窗口切换用户建议搭配使用。

## 开发

```bash
swift build          # 编译
swift test           # 单元测试
swift run mactowin   # 开发模式运行（无图标/无 LSUIElement）
open Package.swift   # 用 Xcode 打开调试
```

调研与路线图见 `docs/research-macos-complaints.md`。

## 安装（首次打开需要手动放行一次）

mactowin 是免费开源软件，未购买 Apple 开发者签名（$99/年），首次打开需手动放行：

1. 双击 mactowin，出现拦截提示
2. 打开「系统设置 → 隐私与安全性」，最下方点「仍要打开」
3. 输入密码，之后永久正常使用

或用一行命令解决：

```bash
xattr -dr com.apple.quarantine ~/Applications/mactowin.app
```

> 使用稳定的自签名证书打包，版本更新后辅助功能/完全磁盘访问授权**不会**失效，无需重新授权。

## 分发

通过 GitHub Releases 免费分发（与 Maccy / AltTab / Rectangle 相同的方式）。
若未来购买 Apple Developer 账号（$99/年），可升级为 Developer ID 签名 + 公证，用户双击即可打开。

## 路线图（未做）

- 终端里图片保存到终端当前工作目录（现在存到设置的位置）
- 剪贴板历史持久化（当前重启清空）
- 外接显示器音量/亮度（DDC）
