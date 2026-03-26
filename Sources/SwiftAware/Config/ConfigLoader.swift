import Foundation

/// Loads SwiftAware configuration
public struct ConfigLoader {

    private static let configFilenames = [
        ".swiftaware.json",
        "swiftaware.json",
        ".swiftaware.config.json"
    ]

    /// Load configuration from file or return defaults
    public static func load(from path: String? = nil) -> AwareConfig {
        do {
            return try loadAndValidate(from: path)
        } catch {
            #if DEBUG
            print("[SwiftAware] Failed to load config: \(error.localizedDescription), using defaults")
            #endif
            return AwareConfig()
        }
    }

    /// Load and validate configuration, throwing on error
    public static func loadAndValidate(from path: String? = nil) throws -> AwareConfig {
        // If explicit path provided
        if let path = path {
            let url = URL(fileURLWithPath: path)
            return try loadFromFile(url)
        }

        // Search for config file in current directory
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath

        for filename in configFilenames {
            let fullPath = (currentDir as NSString).appendingPathComponent(filename)
            if fileManager.fileExists(atPath: fullPath) {
                let url = URL(fileURLWithPath: fullPath)
                return try loadFromFile(url)
            }
        }

        // Search in bundle
        if let bundleURL = Bundle.main.url(forResource: ".swiftaware", withExtension: "json") {
            return try loadFromFile(bundleURL)
        }

        // No config found, return defaults
        return AwareConfig()
    }

    private static func loadFromFile(_ url: URL) throws -> AwareConfig {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(AwareConfig.self, from: data)
    }
}
