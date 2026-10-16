import AppKit

if CommandLine.arguments.contains("--unregister-login-item") {
    LoginItem.isEnabled = false
    exit(0)
}

let delegate = AppDelegate()
NSApplication.shared.delegate = delegate
NSApplication.shared.run()
