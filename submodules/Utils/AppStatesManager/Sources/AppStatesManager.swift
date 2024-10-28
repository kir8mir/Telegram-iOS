import Foundation
import os

public enum AppState: String {
    case normal
    case special
}

public let appStateKey = "appState"
let log = OSLog(subsystem: Bundle.main.bundleIdentifier!, category: "AppState")

public extension Notification.Name {
    static let appStateDidChange = Notification.Name("appStateDidChange")
}

public func getAppState() -> AppState {
    let defaults = UserDefaults.standard
    if let stateString = defaults.string(forKey: appStateKey),
       let state = AppState(rawValue: stateString) {
        return state
    } else {
        return .normal
    }
}

public func setAppState(_ state: AppState) {
//    os_log("_secret_AppState: %{publi\c}@", log: log, type: .info, state.rawValue)
    let defaults = UserDefaults.standard
    defaults.set(state.rawValue, forKey: appStateKey)
    print("PRINT4 Sending notification for app state change to \(state.rawValue)") // Логирование
    NotificationCenter.default.post(name: .appStateDidChange, object: nil)
}

public func observeAppStateChange(_ observer: Any, selector: Selector) {
    NotificationCenter.default.addObserver(observer, selector: selector, name: .appStateDidChange, object: nil)
    print("PRINT4 Observer subscribed") // Проверяем подписку
    }
    
    public func removeAppStateObserver(_ observer: Any) {
        NotificationCenter.default.removeObserver(observer, name: .appStateDidChange, object: nil)
    }
