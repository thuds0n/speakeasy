import SwiftUI

struct AboutView: View {
    private var version: String {
        let v = Bundle.main.releaseVersionNumber ?? "—"
        let b = Bundle.main.buildVersionNumber ?? "—"
        return "Version \(v) (\(b))"
    }

    var body: some View {
        VStack(spacing: 0) {
            VStack(spacing: 12) {
                Image(nsImage: NSApp.applicationIconImage)
                    .resizable()
                    .frame(width: 80, height: 80)
                    .shadow(color: .black.opacity(0.15), radius: 6, y: 3)

                VStack(spacing: 4) {
                    Text("Speakeasy")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Text("Menu bar manager for Mac")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(version)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.top, 28)
            .padding(.bottom, 20)

            Divider()

            VStack(spacing: 0) {
                AboutLink(
                    icon: "heart",
                    label: "Based on Hidden Bar by Dwarves Foundation",
                    url: "https://github.com/dwarvesf/hidden"
                )
            }
            .background(Color(NSColor.controlBackgroundColor))

            Spacer()
        }
        .frame(minHeight: 320)
    }
}

private struct AboutLink: View {
    let icon: String
    let label: String
    let url: String

    var body: some View {
        Link(destination: URL(string: url)!) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .frame(width: 20)
                    .foregroundStyle(.secondary)
                Text(label)
                    .foregroundStyle(.primary)
                Spacer()
                Image(systemName: "arrow.up.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .hoverHighlight()
    }
}

private extension View {
    func hoverHighlight() -> some View {
        self.modifier(HoverHighlightModifier())
    }
}

private struct HoverHighlightModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(isHovered ? Color(NSColor.selectedContentBackgroundColor).opacity(0.1) : .clear)
            .onHover { isHovered = $0 }
    }
}
