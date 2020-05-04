import Foundation

public protocol HotkeyRecorder: class {

    /// Specifies whether recorder is currently recording or not.
    var isRecording: Bool { get set }

    /// Current hotkey.
    var hotkey: KeyboardHotkey? { get set }

    /// Associated hotkey command.
    var command: HotkeyCommand? { get set }
}

extension HotkeyRecorder {
    /// Posted prior hotkey recorder `hotkey` value gets changed, this gets posted both when hotkey is changed
    /// by the outside code and when new hotkey gets recorded.
    public static var hotkeyWillChangeNotification: Notification.Name { Notification.Name("HotkeyRecorderHotkeyWillChangeNotification") }

    /// Posted after hotkey recorder `hotkey` value gets changed, this gets posted both when hotkey is changed
    //    /// by the outside code and when new hotkey gets recorded.
    public static var hotkeyDidChangeNotification: Notification.Name { Notification.Name("HotkeyRecorderHotkeyDidChangeNotification") }

    /// Posted after hotkey recorder `hotkey` value gets changed, this gets posted after `hotkeyWillChange` and `hotkeyDidChange`
    /// notifications, and only when new hotkey was recoded by the user.
    public static var hotkeyDidRecordNotification: Notification.Name { Notification.Name("HotkeyRecorderHotkeyDidRecordNotification") }
}
