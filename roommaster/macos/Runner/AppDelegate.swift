import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }

  func applicationShouldRestoreWindows(_ app: NSApplication) -> Bool {
    // Désactive la restauration d'état pour éviter le log
    // "-[NSApplication(NSWindowRestoration) restoreWindowWithIdentifier...]"
    return false
  }
}
