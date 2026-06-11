import AppKit

enum AppIconProvider {
    static func image(size: NSSize? = nil) -> NSImage {
        let sourceImage = Bundle.main
            .url(forResource: "AppIcon", withExtension: "png")
            .flatMap(NSImage.init(contentsOf:))
            ?? NSImage(systemSymbolName: "bolt.circle.fill", accessibilityDescription: "TorrServer")
            ?? NSImage()

        guard let size else {
            sourceImage.isTemplate = false
            return sourceImage
        }

        let resizedImage = NSImage(size: size)
        resizedImage.lockFocus()
        sourceImage.draw(
            in: NSRect(origin: .zero, size: size),
            from: .zero,
            operation: .sourceOver,
            fraction: 1
        )
        resizedImage.unlockFocus()
        resizedImage.isTemplate = false
        return resizedImage
    }
}
