# macOS 反人类体验调研 & mactowin 进化路线

> 2026-07 调研。来源：知乎「macOS 有哪些难用的地方」「为什么都说 Finder 难用」、水木社区 Apple 版、NGA「20 年 Windows 用户用 macOS 有点坐牢」、julianwest.me「Must-Have Mac Apps for Windows Switchers」、rachitsingh.com「Software to make Macs friendlier to Windows people」、AltTab 官网竞品表、微信公众号「Mac 上的 Finder 真有这么麻烦吗」等。

## 一、全网吐槽聚类（按声量排序）

### 1. 窗口管理 —— 声量最大，Windows 用户第一天就撞墙
- 绿色按钮不是最大化，是「全屏/缩放」，行为不可预期
- 没有 Win+←/→ 贴边分屏（macOS 15 才加了基础 tiling，但无快捷键、发现性极低）
- `⌘Tab` 是**应用级**切换不是窗口级；最小化的窗口在 ⌘Tab 里选中了也切不回来（知乎高赞 bug 级吐槽）
- 关闭（⌘W）≠ 退出（⌘Q），点了红叉 App 还在跑
- 红黄绿按钮只有 15px，「跟个句号似的」
- **现有解法**：Rectangle/Magnet（分屏）、AltTab（窗口级切换）、Contexts
- **竞品强度**：Rectangle 和 AltTab 都免费开源且非常成熟 → 我们不做全套替代品，只做「Windows 键位语义」的最小子集

### 2. 键盘肌肉记忆 —— 每个 Windows 用户都要痛两周
- Home/End 在 Mac 上是跳文档开头/结尾，不是行首/行尾（要按 fn+←/→）
- Ctrl 系快捷键全部变 ⌘ 系；外接 Windows 键盘时 Win 键位置还不一样
- F1-F12 默认是亮度音量，要用 F 键得按 fn
- **现有解法**：Karabiner-Elements（强大但配置像写代码，普通人玩不转）
- **机会点**：「傻瓜版 Karabiner」—— 不做通用重映射，只做「Windows 常用键位一键兼容」开关

### 3. 鼠标/滚轮
- 滚轮方向「自然」与 Windows 相反；系统设置里改掉会连触控板一起改（水木/贴吧高频）
- 第三方鼠标有加速度、发飘
- **现有解法**：MOS、LinearMouse、SteerMouse、BetterMouse
- 可以做：鼠标与触控板滚轮方向**独立**设置

### 4. Finder —— 我们的主场
已被 mactowin 覆盖的：图片粘贴、剪切、新建 txt、路径栏默认关、返回上级
还没覆盖的高频吐槽：
- Enter 是改名不是打开；F2 不存在
- Delete 键不删文件（要 ⌘⌫）
- 没有地址栏（⌘L 输入路径直达）
- 文件夹和文件混排（可设「文件夹置顶」但藏得深）
- 搜索默认搜「这台 Mac」慢成蜗牛（应默认当前文件夹）
- 确认弹窗太多（清倒废纸篓、改扩展名、iCloud 删除）
- 视图设置无法全局默认（水木热帖）
- 压缩/解压功能弱（The Unarchiver/Keka 因此存在）

### 5. 系统层
- 外接显示器音量/亮度不能调（CEC/DDC 缺失 → MonitorControl/BetterDisplay）
- 刘海挡住菜单栏图标（Bartender/Ice）
- `._` 开头垃圾文件
- NTFS 移动硬盘只读

## 二、竞品格局与 mactowin 定位

| 痛点 | 现有工具 | 状态 |
|---|---|---|
| 窗口分屏 | Rectangle / Magnet / Loop | 红海，免费开源 |
| 窗口级切换 | AltTab / Contexts | 红海，免费开源 |
| 键盘重映射 | Karabiner-Elements | 免费但极难配置 |
| 滚轮/鼠标 | MOS / LinearMouse | 免费小工具 |
| 外显音量 | MonitorControl | 免费开源 |
| 菜单栏管理 | Bartender / Ice | Ice 免费开源 |
| 剪贴板 | Paste / Maccy / Raycast | 红海 |
| **Windows 迁移者一站式兼容层** | **无** | **空白** |

**结论**：单点功能全是红海，但「一个 App、一套开关、全部模拟 Windows 语义」没有人做。
mactowin 的卖点 = **不用装 7 个 App**。对竞品的态度：不替代 Rectangle/AltTab，
我们覆盖「键位语义和系统行为」这层，并在 README 推荐重度用户搭配 AltTab。

## 三、功能批次规划

### Batch A · Finder 收尾（主场，壁垒已有，工作量小）
- Enter 打开 / F2 改名（映射框架已就绪）
- fn+Delete → ⌘⌫ 删除文件（Windows 的 Delete 语义）
- ⌘L 地址栏输入路径（映射 ⌘⇧G）
- Alt+Enter 显示简介（映射 ⌘I）
- 一键开关：搜索默认当前文件夹 / 文件夹置顶 / 关闭确认弹窗 / 显示扩展名 / 全局列表视图

### Batch B · 键盘习惯（差异化最大）
- Home/End → 行首/行尾（全局文本域）
- 「Windows 键位兼容」总开关：Ctrl+C/V/X/Z/A/S → ⌘ 系（给改不过来的用户）
- F1-F12 默认标准功能键开关

### Batch C · 窗口管理（只做 Windows 键位语义，不做 tiling）
- ⌃⌥←/→ 左半屏/右半屏、⌃⌥↑ 最大化（AX API 移窗，不做全屏）
- 双击标题栏 = 最小化 开关

### Batch D · 鼠标
- 鼠标与触控板滚轮方向独立设置
- 关闭鼠标加速

### 明确不做
- 窗口级 ⌘Tab 替代（AltTab 已免费且优秀，README 推荐搭配）
- 菜单栏图标管理（Bartender/Ice 领域，工程量与收益不匹配）
- NTFS 写入（系统级驱动，风险高）
