import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var settings: SettingsStore
    @State private var showAlwaysHiddenHelp = false

    // MARK: - Body

    var body: some View {
        Form {
            startupSection
            menuBarSection
            autoCollapseSection
            shortcutSection
        }
        .formStyle(.grouped)
        .frame(minWidth: 400, minHeight: 360)
    }

    // MARK: - Sections

    private var startupSection: some View {
        Section("Startup") {
            Toggle("Launch Speakeasy at login", isOn: $settings.isAutoStart)
            Toggle("Show preferences on launch", isOn: $settings.isShowPreference)
        }
    }

    private var menuBarSection: some View {
        Section {
            MenuBarDiagramView(alwaysHiddenEnabled: settings.alwaysHiddenSectionEnabled)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

            Toggle("Enable always hidden section", isOn: $settings.alwaysHiddenSectionEnabled)
                .overlay(alignment: .trailing) {
                    Button {
                        showAlwaysHiddenHelp = true
                    } label: {
                        Image(systemName: "questionmark.circle")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                    .popover(isPresented: $showAlwaysHiddenHelp, arrowEdge: .trailing) {
                        alwaysHiddenHelpPopover
                    }
                    .offset(x: -8)
                }

            Toggle("Use full menu bar when expanded", isOn: $settings.useFullStatusBarOnExpandEnabled)
        } header: {
            Text("Menu Bar")
        }
    }

    private var autoCollapseSection: some View {
        Section("Auto-Collapse") {
            Toggle("Automatically collapse after a delay", isOn: $settings.isAutoHide)

            if settings.isAutoHide {
                Picker("Collapse after", selection: $settings.autoHideDuration) {
                    Text("5 seconds").tag(5.0)
                    Text("10 seconds").tag(10.0)
                    Text("15 seconds").tag(15.0)
                    Text("30 seconds").tag(30.0)
                    Text("1 minute").tag(60.0)
                }
            }
        }
    }

    private var shortcutSection: some View {
        Section("Global Shortcut") {
            LabeledContent("Toggle hidden items") {
                ShortcutRecorderView(shortcut: $settings.globalKey)
                    .frame(width: 200, height: 28)
            }
        }
    }

    // MARK: - Help popover

    private var alwaysHiddenHelpPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Always Hidden Section", systemImage: "rectangle.slash")
                .font(.headline)
            Text("""
                Creates a third section that stays permanently hidden.

                1. Enable this option — a translucent bar appears in your menu bar.
                2. Hold ⌘ and drag icons to the left of that bar to permanently hide them.
                3. Right-click the collapse button (›) to hide it from view.

                To reveal always-hidden icons: right-click the collapse button again.
                """)
                .font(.callout)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(width: 300)
    }
}
