import SwiftUI

/// A schematic illustration of how Speakeasy partitions the macOS menu bar.
struct MenuBarDiagramView: View {
    let alwaysHiddenEnabled: Bool

    var body: some View {
        VStack(spacing: 10) {
            diagramBar
            caption
        }
        .padding(.vertical, 6)
        .animation(.easeInOut(duration: 0.2), value: alwaysHiddenEnabled)
    }

    // MARK: - Bar

    private var diagramBar: some View {
        HStack(spacing: 0) {
            if alwaysHiddenEnabled {
                zone(label: "Always\nHidden", dots: 2, color: .red.opacity(0.55))
                barSeparator(icon: "rectangle.slash")
            }
            zone(label: "Hidden", dots: 3, color: .orange.opacity(0.6))
            collapseMarker
            zone(label: "Shown", dots: 3, color: .green.opacity(0.55))
            clockChip
        }
        .frame(height: 36)
        .background(Color(NSColor.controlBackgroundColor))
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color(NSColor.separatorColor), lineWidth: 0.5)
        )
    }

    private func zone(label: String, dots: Int, color: Color) -> some View {
        HStack(spacing: 4) {
            ForEach(0..<dots, id: \.self) { _ in
                RoundedRectangle(cornerRadius: 2)
                    .fill(color)
                    .frame(width: 10, height: 10)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 6)
    }

    private func barSeparator(icon: String) -> some View {
        Rectangle()
            .fill(Color(NSColor.separatorColor))
            .frame(width: 1)
            .padding(.vertical, 4)
    }

    private var collapseMarker: some View {
        ZStack {
            Rectangle()
                .fill(Color(NSColor.separatorColor))
                .frame(width: 1)
                .padding(.vertical, 4)

            Image(systemName: "chevron.compact.right")
                .font(.system(size: 10, weight: .semibold))
                .foregroundStyle(.secondary)
                .background(
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(NSColor.controlBackgroundColor))
                        .padding(-2)
                )
        }
    }

    private var clockChip: some View {
        HStack(spacing: 3) {
            Image(systemName: "wifi")
                .font(.system(size: 9))
            Text("9:41")
                .font(.system(size: 10, weight: .medium, design: .monospaced))
        }
        .foregroundStyle(.secondary)
        .padding(.trailing, 8)
    }

    // MARK: - Caption

    private var caption: some View {
        HStack(spacing: 0) {
            if alwaysHiddenEnabled {
                Label("Always Hidden", systemImage: "rectangle.slash")
                    .foregroundStyle(.red.opacity(0.7))
                dotSpacer
            }
            Label("Hidden", systemImage: "eye.slash")
                .foregroundStyle(.orange.opacity(0.8))
            dotSpacer
            Label("Shown", systemImage: "eye")
                .foregroundStyle(.green.opacity(0.8))
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
    }

    private var dotSpacer: some View {
        Text(" · ").foregroundStyle(.tertiary)
    }
}
