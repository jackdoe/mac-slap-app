import Foundation

nonisolated enum AppInfo {
    static let name = "SlapMe"
    static let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "dev"
    static let isBundled = Bundle.main.bundleURL.pathExtension == "app"

    static var isInstalled: Bool {
        let folder = Bundle.main.bundleURL.deletingLastPathComponent().standardizedFileURL
        let applications = [
            URL(filePath: "/Applications", directoryHint: .isDirectory),
            URL.homeDirectory.appending(path: "Applications", directoryHint: .isDirectory),
        ]
        return isBundled && applications.map(\.standardizedFileURL).contains(folder)
    }
}
