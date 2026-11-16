// Designed by TiantianYe
import Foundation
import SwiftUI

struct APIConfiguration: Codable {
    var baseURL: String
    var model: String
    var reasonerModel: String

    static let `default` = APIConfiguration(
        baseURL: "https://api.deepseek.com",
        model: "deepseek-chat",
        reasonerModel: "deepseek-reasoner"
    )
}

@MainActor
final class AppPreferences: ObservableObject {
    @Published var configuration: APIConfiguration {
        didSet {
            if let data = try? JSONEncoder().encode(configuration) {
                UserDefaults.standard.set(data, forKey: Keys.configuration)
            }
        }
    }

    private enum Keys {
        static let configuration = "prefs.api_configuration"
    }

    init() {
        let defaults = UserDefaults.standard
        if let data = defaults.data(forKey: Keys.configuration),
           let config = try? JSONDecoder().decode(APIConfiguration.self, from: data) {
            self.configuration = config
        } else {
            self.configuration = .default
        }
    }

    var apiKey: String {
        get { Keychain.shared.load() ?? "" }
        set {
            try? Keychain.shared.save(newValue)
            objectWillChange.send()
        }
    }

    var isConfigured: Bool {
        !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
