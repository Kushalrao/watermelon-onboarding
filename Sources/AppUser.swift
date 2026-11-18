import Foundation

/// Who the app is talking to. Every greeting and message that names the user reads it from here, so changing
/// `name` changes it across the app; `-userName Someone` at launch does the same for one run.
enum AppUser {
    static let name: String = {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-userName"), i + 1 < args.count { return args[i + 1] }
        return "Venkat"
    }()
}
