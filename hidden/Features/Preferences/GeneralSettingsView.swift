import SwiftUI

struct GeneralSettingsView: View {

    // MARK: - State (mirrors Preferences, written back on change)

    @State private var isAutoStart               = Preferences.isAutoStart
    @State private var isShowPreference          = Preferences.isShowPreference
    @State private var useFullStatusBar          = Preferences.useFullStatusBarOnExpandEnabled
    @State private var alwaysHiddenEnabled       = Preferences.alwaysHiddenSectionEnabled
    @State private var isAutoHide                = Preferences.isAutoHide
    @State private var autoHideDuration          = Preferences.numberOfSecondForAutoHide
    @State private var shortcut: GlobalKeybindPreferences? = Preferences.globalKey

    @State private var showAlwaysHiddenHelp      = false

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
        .onAppear(perform: reloadFromPreferences)
    }

    // MARK: - Sections

    private var startupSection: some View {
        Section("Startup") {
            Toggle("Launch Speakeasy at login", isOn: $isAutoStart)
                .onChange(of: isAutoStart, perform: { Preferences.isAutoStart = $0 })
            Toggle("Show preferences on launch", isOn: $isShowPreference)
                .onChange(of: isShowPreference, perform: { Preferences.isShowPreference = $0 })
        }
    }

    private var menuBarSection: some View {
        Section {
            MenuBarDiagramView(alwaysHiddenEnabled: alwaysHiddenEnabled)
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)

            Toggle("Enable always hidden section", isOn: $alwaysHiddenEnabled)
                .onChange(of: alwaysHiddenEnabled, perform: { Preferences.alwaysHiddenSectionEnabled = $0 })
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

            Toggle("Use full menu bar when expanded", isOn: $useFullStatusBar)
                .onChange(of: useFullStatusBar, perform: { Preferences.useFullStatusBarOnExpandEnabled = $0 })
        } header: {
            Text("Menu Bar")
        }
    }

    private var autoCollapseSection: some View {
        Section("Auto-Collapse") {
            Toggle("Automatically collapse after a delay", isOn: $isAutoHide)
                .onChange(of: isAutoHide, perform: { Preferences.isAutoHide = $0 })

            if isAutoHide {
                Picker("Collapse after", selection: $autoHideDuration) {
                    Text("5 seconds").tag(5.0)
                    Text("10 seconds").tag(10.0)
                    Text("15 seconds").tag(15.0)
                    Text("30 seconds").tag(30.0)
                    Text("1 minute").tag(60.0)
                }
                .onChange(of: autoHideDuration, perform: { Preferences.numberOfSecondForAutoHide = $0 })
            }
        }
    }

    private var shortcutSection: some View {
        Section("Global Shortcut") {
            LabeledContent("Toggle hidden items") {
                ShortcutRecorderView(shortcut: $shortcut)
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

    // MARK: - Reload

    private func reloadFromPreferences() {
        isAutoStart         = Preferences.isAutoStart
        isShowPreference    = Preferences.isShowPreference
        useFullStatusBar    = Preferences.useFullStatusBarOnExpandEnabled
        alwaysHiddenEnabled = Preferences.alwaysHiddenSectionEnabled
        isAutoHide          = Preferences.isAutoHide
        autoHideDuration    = Preferences.numberOfSecondForAutoHide
        shortcut            = Preferences.globalKey
    }
}
