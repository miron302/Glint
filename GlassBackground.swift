import SwiftUI
import AppKit

/// The visual heart of Glint. On macOS 26 ("Tahoe") and later this uses
/// Apple's real Liquid Glass material via `.glassEffect`. On older macOS
/// versions it falls back to a tinted `NSVisualEffectView`, which looks
/// close but doesn't have the true refractive/specular Liquid Glass look —
/// there's no way to fake the real material pre-26.
struct GlassBackground: View {
    @ObservedObject var settings = AppSettings.shared

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: settings.cornerRadius, style: .continuous)

        Group {
            if #available(macOS 26.0, *) {
                shape
                    .fill(.clear)
                    .glassEffect(
                        .regular.tint(settings.tintColor.opacity(settings.glassIntensity)),
                        in: shape
                    )
            } else {
                ZStack {
                    VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                    shape.fill(settings.tintColor.opacity(settings.glassIntensity * 0.18))
                    shape.strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                }
                .clipShape(shape)
            }
        }
        .shadow(color: .black.opacity(0.35), radius: 30, x: 0, y: 18)
    }
}

/// Thin NSViewRepresentable wrapper around NSVisualEffectView for the
/// pre-macOS-26 fallback path.
struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material
    var blendingMode: NSVisualEffectView.BlendingMode

    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
