import Foundation

enum AuraSection: String, CaseIterable, Identifiable {
    case dashboard = "Dashboard"
    case containers = "Containers"
    case images = "Images"
    case volumes = "Volumes"
    case networks = "Networks"
    case converter = "Converter"
    case logs = "Logs"
    case settings = "Settings"

    var id: String { rawValue }

    var iconName: String {
        switch self {
        case .dashboard: "rectangle.grid.2x2"
        case .containers: "shippingbox"
        case .images: "photo.on.rectangle.angled"
        case .volumes: "internaldrive"
        case .networks: "network"
        case .converter: "arrow.left.arrow.right"
        case .logs: "doc.text.magnifyingglass"
        case .settings: "gearshape"
        }
    }
}
