import SwiftUI

struct SettingsView: View {
    enum Tab: String, CaseIterable {
        case general = "General"
        case models = "Models"
        case writing = "Writing"

        var icon: String {
            switch self {
            case .general: return "gearshape"
            case .models: return "cpu"
            case .writing: return "square.and.pencil"
            }
        }
    }

    @State private var selectedTab: Tab = .general

    var body: some View {
        VStack(spacing: 0) {
            tabBar

            Divider()

            Group {
                switch selectedTab {
                case .general:
                    GeneralSettingsView()
                case .models:
                    APIKeySettingsView()
                case .writing:
                    WritingStyleView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(minWidth: 540, minHeight: 560)
    }

    // Preferences-style toolbar tabs: icon over label, like native macOS
    // settings windows.
    private var tabBar: some View {
        HStack(spacing: 6) {
            ForEach(Tab.allCases, id: \.self) { tab in
                TabBarButton(tab: tab, isSelected: selectedTab == tab) {
                    selectedTab = tab
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 5)
        .background(Color(nsColor: .windowBackgroundColor))
    }
}

private struct TabBarButton: View {
    let tab: SettingsView.Tab
    let isSelected: Bool
    let action: () -> Void

    @State private var hovering = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .regular))
                    .symbolVariant(isSelected ? .fill : .none)
                    .frame(height: 18)
                Text(tab.rawValue)
                    .font(.system(size: 11))
            }
            .foregroundStyle(isSelected ? Color.accentColor : Color.secondary)
            .frame(width: 66, height: 46)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(isSelected ? 0.07 : (hovering ? 0.04 : 0)))
            )
            .contentShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { hovering = $0 }
    }
}
