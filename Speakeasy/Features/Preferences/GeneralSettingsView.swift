import SwiftUI

struct GeneralSettingsView: View {
    @ObservedObject var settings: SettingsStore
    @ObservedObject var launchAtLogin: LaunchAtLoginController
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
        .frame(minWidth: 400, minHeight: 390)
        .onAppear(perform: launchAtLogin.refresh)
    }

    // MARK: - Sections

    private var startupSection: some View {
        Section("Startup") {
            Toggle("Launch Speakeasy at login", isOn: launchAtLoginBinding)
                .disabled(launchAtLogin.status == .unavailable)
            LaunchAtLoginStatusView(controller: launchAtLogin)
            Toggle("Show preferences on launch", isOn: $settings.isShowPreference)
        }
    }

    private var launchAtLoginBinding: Binding<Bool> {
        Binding(
            get: { launchAtLogin.isEnabled },
            set: launchAtLogin.setEnabled
        )
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

private struct LaunchAtLoginStatusView: View {
    @ObservedObject var controller: LaunchAtLoginController

    var body: some View {
        Label(statusText, systemImage: statusIcon)
            .font(.caption)
            .foregroundStyle(statusColor)
            .accessibilityElement(children: .combine)

        if controller.status == .requiresApproval {
            Button("Open Login Items Settings", action: controller.openSystemSettings)
                .controlSize(.small)
                .help("Open macOS System Settings to approve Speakeasy as a login item.")
                .accessibilityHint("Opens the Login Items section in System Settings.")
        }

        if let errorMessage = controller.errorMessage {
            Label(errorMessage, systemImage: "xmark.octagon.fill")
                .font(.caption)
                .foregroundStyle(.red)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityElement(children: .combine)
        }
    }

    private var statusText: String {
        switch controller.status {
        case .disabled:
            return "Not configured to launch at login"
        case .enabled:
            return "Enabled in macOS Login Items"
        case .requiresApproval:
            return "Approval required in macOS System Settings"
        case .unavailable:
            return "Login item status is unavailable"
        }
    }

    private var statusIcon: String {
        switch controller.status {
        case .disabled:
            return "minus.circle"
        case .enabled:
            return "checkmark.circle.fill"
        case .requiresApproval:
            return "exclamationmark.triangle.fill"
        case .unavailable:
            return "xmark.circle.fill"
        }
    }

    private var statusColor: Color {
        switch controller.status {
        case .disabled:
            return .secondary
        case .enabled:
            return .green
        case .requiresApproval:
            return .orange
        case .unavailable:
            return .red
        }
    }
}
