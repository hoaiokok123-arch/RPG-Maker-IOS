import Foundation

enum GameInputDispatcher {
    static func post(_ event: VirtualGamepadEvent, source: AnyObject? = nil) {
        NotificationCenter.default.post(
            name: .virtualGamepadEventDidChange,
            object: source,
            userInfo: [VirtualGamepadEvent.notificationUserInfoKey: event]
        )
    }
}
