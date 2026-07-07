#!/usr/bin/env swift
//
// Generates the App Store Connect achievement images: phosphor-green
// circular ring + monospaced glyph on the app's terminal background.
// Game Center masks achievement art to a circle, so the ring matches.
//
// The PNGs are one-time ASC uploads and are not committed; this script
// is their source of truth. Regenerate after adding an achievement:
//
//   swift Tools/gen_achievement_art.swift ~/Downloads/SudoSodoku-achievement-art
//
// Keep the slugs in sync with `Achievement` (Models/Achievement.swift).

import AppKit

let achievements: [(slug: String, glyph: String)] = [
    ("hello_world", ">_"),
    ("uptime_10", "10"),
    ("uptime_50", "50"),
    ("uptime_100", "100"),
    ("root_privileges", "#"),
    ("clean_commit", "OK"),
    ("overclocked", ">>"),
    ("rank_sudoer", "1400"),
    ("rank_sysadmin", "1600"),
    ("rank_kernel_hacker", "1800"),
    ("rank_architect", "2000"),
    ("incident_reported", "!"),
]

let pixels = 1024
let outDir = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "."
try? FileManager.default.createDirectory(atPath: outDir, withIntermediateDirectories: true)

let background = NSColor(red: 0.05, green: 0.07, blue: 0.10, alpha: 1)
let phosphor = NSColor(red: 0.15, green: 1.0, blue: 0.3, alpha: 1)

for item in achievements {
    guard let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: pixels, pixelsHigh: pixels,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
    ) else { continue }

    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let full = NSRect(x: 0, y: 0, width: pixels, height: pixels)
    background.setFill()
    full.fill()

    phosphor.setStroke()
    let ring = NSBezierPath(ovalIn: full.insetBy(dx: 72, dy: 72))
    ring.lineWidth = 16
    ring.stroke()

    phosphor.withAlphaComponent(0.25).setStroke()
    let outerGlow = NSBezierPath(ovalIn: full.insetBy(dx: 48, dy: 48))
    outerGlow.lineWidth = 8
    outerGlow.stroke()

    let fontSize: CGFloat = item.glyph.count > 2 ? 300 : 440
    let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .bold)
    let text = NSAttributedString(string: item.glyph, attributes: [
        .font: font,
        .foregroundColor: phosphor,
    ])
    let textSize = text.size()
    text.draw(at: NSPoint(
        x: (CGFloat(pixels) - textSize.width) / 2,
        y: (CGFloat(pixels) - textSize.height) / 2
    ))

    NSGraphicsContext.restoreGraphicsState()

    guard let png = rep.representation(using: .png, properties: [:]) else { continue }
    let url = URL(fileURLWithPath: "\(outDir)/\(item.slug).png")
    try? png.write(to: url)
    print("wrote \(url.lastPathComponent)")
}
print("done -> \(outDir)")
