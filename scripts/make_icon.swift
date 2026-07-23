// 生成 1024x1024 应用图标 PNG：蓝色渐变圆角矩形 + 白色 "W" + 右箭头
// 用法: swift scripts/make_icon.swift /tmp/winbridge_icon_1024.png
import AppKit

let size: CGFloat = 1024
let outputPath = CommandLine.arguments.count > 1
    ? CommandLine.arguments[1]
    : "/tmp/winbridge_icon_1024.png"

let image = NSImage(size: NSSize(width: size, height: size))
image.lockFocus()

// 圆角矩形背景 + 渐变
let rect = NSRect(x: 0, y: 0, width: size, height: size)
let path = NSBezierPath(roundedRect: rect.insetBy(dx: 24, dy: 24), xRadius: 220, yRadius: 220)
let gradient = NSGradient(colors: [
    NSColor(calibratedRed: 0.16, green: 0.45, blue: 0.95, alpha: 1),
    NSColor(calibratedRed: 0.45, green: 0.25, blue: 0.90, alpha: 1),
])!
gradient.draw(in: path, angle: -45)

// 白色 "W"
let letter = "M"
let font = NSFont.systemFont(ofSize: 620, weight: .heavy)
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: NSColor.white,
]
let letterSize = letter.size(withAttributes: attrs)
let letterRect = NSRect(
    x: (size - letterSize.width) / 2,
    y: (size - letterSize.height) / 2 - 60,
    width: letterSize.width,
    height: letterSize.height
)
letter.draw(in: letterRect, withAttributes: attrs)

// 底部小箭头 "→"（Win → Mac 的含义）
let arrow = "→"
let arrowFont = NSFont.systemFont(ofSize: 180, weight: .bold)
let arrowAttrs: [NSAttributedString.Key: Any] = [
    .font: arrowFont,
    .foregroundColor: NSColor.white.withAlphaComponent(0.9),
]
let arrowSize = arrow.size(withAttributes: arrowAttrs)
arrow.draw(
    in: NSRect(x: (size - arrowSize.width) / 2, y: 70, width: arrowSize.width, height: arrowSize.height),
    withAttributes: arrowAttrs
)

image.unlockFocus()

guard let tiff = image.tiffRepresentation,
      let rep = NSBitmapImageRep(data: tiff),
      let png = rep.representation(using: .png, properties: [:]) else {
    FileHandle.standardError.write("生成 PNG 失败\n".data(using: .utf8)!)
    exit(1)
}
try png.write(to: URL(fileURLWithPath: outputPath))
print("已生成 \(outputPath)")
