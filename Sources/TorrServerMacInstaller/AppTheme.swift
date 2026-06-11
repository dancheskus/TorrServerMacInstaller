import AppKit
import SwiftUI

enum AppTheme {
    static let background = Color(hex: 0x111319)
    static let backgroundEdge = Color(hex: 0x0C0E14)
    static let sidebar = Color(hex: 0x141720)
    static let surface = Color(hex: 0x1E1F26)
    static let surfaceHigh = Color(hex: 0x282A30)
    static let surfaceHighest = Color(hex: 0x33343B)
    static let text = Color(hex: 0xE2E2EB)
    static let textMuted = Color(hex: 0xBECABA)
    static let outline = Color(hex: 0x3F4A3D)
    static let primary = Color(hex: 0x71DD7F)
    static let primaryDark = Color(hex: 0x44B058)
    static let onPrimary = Color(hex: 0x003911)
    static let secondary = Color(hex: 0xADC6FF)
    static let stopped = Color(hex: 0xFFB3AD)
    static let error = Color(hex: 0xFFB4AB)

    static func statusColor(_ status: ServerStatus) -> Color {
        switch status {
        case .running:
            primary
        case .error:
            error
        case .stopped, .notInstalled:
            stopped
        default:
            secondary
        }
    }

    static var appBackground: some View {
        RadialGradient(
            colors: [Color(hex: 0x1B2233), background, backgroundEdge],
            center: UnitPoint(x: 0.35, y: 0.2),
            startRadius: 80,
            endRadius: 900
        )
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

struct TechnicalSectionTitle: View {
    let title: String
    let systemImage: String

    var body: some View {
        Label(title, systemImage: systemImage)
            .font(.system(size: 13, weight: .semibold, design: .monospaced))
            .foregroundStyle(AppTheme.text)
            .labelStyle(.titleAndIcon)
    }
}

struct StatusDot: View {
    let color: Color

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 8, height: 8)
            .shadow(color: color.opacity(0.65), radius: 5)
    }
}

struct TechnicalButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled

    enum Kind {
        case primary
        case secondary
        case icon
    }

    let kind: Kind

    init(_ kind: Kind = .secondary) {
        self.kind = kind
    }

    func makeBody(configuration: Configuration) -> some View {
        TechnicalButtonBody(
            configuration: configuration,
            kind: kind,
            isEnabled: isEnabled
        )
    }
}

private struct TechnicalButtonBody: View {
    let configuration: ButtonStyle.Configuration
    let kind: TechnicalButtonStyle.Kind
    let isEnabled: Bool
    @State private var isHovered = false

    var body: some View {
        configuration.label
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(foreground)
            .opacity(isEnabled ? 1 : 0.48)
            .frame(maxWidth: kind == .icon ? nil : .infinity)
            .padding(.horizontal, kind == .icon ? 8 : 14)
            .padding(.vertical, kind == .icon ? 7 : 10)
            .background(background)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(border, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .scaleEffect(configuration.isPressed && isEnabled ? 0.985 : 1)
            .animation(.easeInOut(duration: 0.12), value: isHovered)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
            .onHover { hovering in
                isHovered = hovering
                if isEnabled {
                    hovering ? NSCursor.pointingHand.set() : NSCursor.arrow.set()
                }
            }
    }

    private var foreground: Color {
        switch kind {
        case .primary:
            isEnabled ? AppTheme.onPrimary : AppTheme.textMuted
        case .secondary, .icon:
            isEnabled ? AppTheme.text : AppTheme.textMuted
        }
    }

    private var border: Color {
        switch kind {
        case .primary:
            isEnabled ? AppTheme.primary.opacity(isHovered ? 1 : 0.75) : AppTheme.outline.opacity(0.5)
        case .secondary, .icon:
            if isEnabled && isHovered {
                AppTheme.primary.opacity(0.72)
            } else {
                AppTheme.outline.opacity(isEnabled ? 1 : 0.45)
            }
        }
    }

    private var background: some View {
        Group {
            switch kind {
            case .primary:
                LinearGradient(
                    colors: [
                        isEnabled ? AppTheme.primary.opacity(primaryOpacity) : AppTheme.surfaceHigh.opacity(0.45),
                        isEnabled ? AppTheme.primaryDark.opacity(primaryOpacity) : AppTheme.surface.opacity(0.45)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            case .secondary:
                AppTheme.surfaceHigh.opacity(isEnabled ? secondaryOpacity : 0.32)
            case .icon:
                AppTheme.surfaceHigh.opacity(isEnabled ? iconOpacity : 0.28)
            }
        }
    }

    private var primaryOpacity: Double {
        if configuration.isPressed { return 0.78 }
        return isHovered ? 0.96 : 0.92
    }

    private var secondaryOpacity: Double {
        if configuration.isPressed { return 0.92 }
        return isHovered ? 0.8 : 0.72
    }

    private var iconOpacity: Double {
        if configuration.isPressed { return 0.9 }
        return isHovered ? 0.72 : 0.62
    }
}

struct TechnicalFieldModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .textFieldStyle(.plain)
            .font(.system(size: 13, weight: .medium, design: .monospaced))
            .foregroundStyle(AppTheme.text)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(AppTheme.surface.opacity(0.72), in: RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(AppTheme.outline, lineWidth: 1)
            )
    }
}

extension View {
    func technicalField() -> some View {
        modifier(TechnicalFieldModifier())
    }
}
