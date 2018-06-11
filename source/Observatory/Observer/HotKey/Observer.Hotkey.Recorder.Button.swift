import AppKit
import Foundation
import Carbon

/// - note: Earlier we used `viewWillDraw` callback to perform the update, but it doesn't always work in real life
///         as expected, so we call it directly with internal optimisation.
open class HotkeyRecorderButton: NSButton, HotkeyRecorder
{

    private lazy var windowNotificationObserver: NotificationObserver = NotificationObserver(active: true)

    open var hotkey: KeyboardHotkey? {
        willSet {
            if self.hotkey == newValue { return }
            NotificationCenter.default.post(name: HotkeyRecorderButton.hotkeyWillChangeNotification, object: self)
        }
        didSet {
            if self.hotkey == oldValue { return }

            // Should cancel recording if we're setting hotkey while recording.

            self.register()

            // Wtf??? See class notes…

            if self.isRecording != false {
                self.isRecording = false
            } else {
                self.update()
            }

            NotificationCenter.default.post(name: HotkeyRecorderButton.hotkeyDidChangeNotification, object: self)
        }
    }

    open var command: HotkeyCommand? {
        didSet {
            if self.command == oldValue { return }

            self.register()
            self.update()
        }
    }

    /// Successfully registered hotkey-command tuple.
    private var registration: (hotkey: KeyboardHotkey, command: HotkeyCommand)?

    /// Attempts to update registration to current command and hotkey.
    private func register() {
        let oldHotkey: KeyboardHotkey? = self.registration?.hotkey
        let newHotkey: KeyboardHotkey? = self.hotkey
        let oldCommand: HotkeyCommand? = self.registration?.command
        let newCommand: HotkeyCommand? = self.command

        if newHotkey == oldHotkey && newCommand == oldCommand {
            return
        }

        if let oldHotkey: KeyboardHotkey = oldHotkey, HotkeyCenter.default.commands[oldHotkey] == self.command {
            HotkeyCenter.default.remove(hotkey: oldHotkey)
        }

        // Todo: it would be good to return some status, but because definitions might not fail immediately this is a non-trivial job. Leaving it
        // todo: as a reminder in case this ever proves to be a problem…

        if let newHotkey: KeyboardHotkey = newHotkey, let newCommand: HotkeyCommand = newCommand {
            HotkeyCenter.default.add(hotkey: newHotkey, command: newCommand)
            self.registration = (newHotkey, newCommand)
        } else {
            self.registration = nil
        }
    }

    open var isRecording: Bool = false {
        didSet {
            if self.isRecording == oldValue { return }

            // Wtf??? See class notes…

            if self.modifier != nil {
                self.modifier = nil
            } else {
                self.update()
            }

            // Let hotkey center know that current recorder changed.

            if self.isRecording {
                HotkeyCenter.default.recorder = self
            } else if HotkeyCenter.default.recorder === self {
                HotkeyCenter.default.recorder = nil
            }
        }
    }

    /// Stores temporary modifier while hotkey is being recorded.
    private var modifier: KeyboardModifier? {
        didSet {
            if self.modifier == oldValue { return }
            self.update()
        }
    }

    private func update() {

        // In case if title is empty, we still need a valid paragraph style…

        let style: NSMutableParagraphStyle = self.attributedTitle.attribute(NSAttributedStringKey.paragraphStyle, at: 0, effectiveRange: nil) as! NSMutableParagraphStyle? ?? NSMutableParagraphStyle(alignment: self.alignment)
        let colour: NSColor
        let title: String

        if self.isRecording {
            self.window!.makeFirstResponder(self)

            if let modifier: KeyboardModifier = self.modifier, modifier != [] {
                title = self.title(forModifier: modifier)
            } else if let hotkey: KeyboardHotkey = self.hotkey {
                title = self.title(forHotkey: hotkey)
            } else {
                title = "Record hotkey"
            }

            colour = self.modifier == nil ? NSColor.tertiaryLabelColor : NSColor.secondaryLabelColor
        } else {
            if let hotkey: KeyboardHotkey = self.hotkey {

                // Hotkey and command are set and registered the button will appear normal. If hotkey is set but command is not the button
                // will appear grayed out. If hotkey and command are set but not registered the button will have a warning.

                if self.registration != nil || self.command == nil {
                    title = self.title(forHotkey: hotkey)
                    colour = self.command == nil ? NSColor.secondaryLabelColor : NSColor.labelColor
                } else {

                    // Todo: this is all fancy shmancy, but we need a proper solution here…

                    title = "☠️"
                    colour = NSColor.secondaryLabelColor
                }
            } else {
                title = "Click to record hotkey"
                colour = NSColor.labelColor
            }
        }

        if title == "" {
            NSLog("\(self) attempted to set empty title, this shouldn't be happening…")
        } else {
            self.attributedTitle = NSAttributedString(string: title, attributes: [.foregroundColor: colour, .paragraphStyle: style, .font: self.font ?? NSFont.systemFont(ofSize: NSFont.systemFontSize)])
        }
    }

    open func title(forModifier modifier: KeyboardModifier) -> String {
        return String(describing: modifier)
    }

    open func title(forKey key: KeyboardKey) -> String {
        return String(describing: key)
    }

    open func title(forHotkey hotkey: KeyboardHotkey) -> String {
        return "\(self.title(forModifier: hotkey.modifier))\(self.title(forKey: hotkey.key))"
    }

    override open func resignFirstResponder() -> Bool {
        self.isRecording = false
        return super.resignFirstResponder()
    }

    override open var acceptsFirstResponder: Bool {
        return self.isEnabled
    }

    override open func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        self.isRecording = true
    }

    override open func keyDown(with event: NSEvent) {
        if !self.performKeyEquivalent(with: event) {
            super.keyDown(with: event)
        }
    }

    /// Handles hotkey recording and returns true when any custom logic was invoked.
    override open func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard self.isEnabled else {
            return false
        }

        // Pressing delete key without any modifiers clears current shortcut.

        if KeyboardKey(event) == KeyboardKey.delete && self.modifier == nil && self.hotkey != nil {
            self.hotkey = nil
            self.isRecording = false
            NotificationCenter.default.post(name: HotkeyRecorderButton.hotkeyDidRecordNotification, object: self)
            return true
        }

        // Pressing escape without modifiers during recording cancels it, pressing space while not recording starts it.

        if self.isRecording && KeyboardKey(event) == KeyboardKey.escape && self.modifier == nil {
            self.isRecording = false
            return true
        } else if !self.isRecording && KeyboardKey(event) == KeyboardKey.space {
            self.isRecording = true
            return true
        }

        // If not recording, there's nothing else to do…

        if !self.isRecording {
            return super.performKeyEquivalent(with: event)
        }

        // Pressing any key without modifiers is not a valid shortcut.

        if let modifier: KeyboardModifier = self.modifier {
            let hotkey: KeyboardHotkey = KeyboardHotkey(key: KeyboardKey(event), modifier: modifier)

            if HotkeyCenter.default.commands.keys.contains(hotkey) && HotkeyCenter.default.commands[hotkey] != self.command {
                NSSound.beep()
            } else {
                self.hotkey = hotkey
                self.isRecording = false
                NotificationCenter.default.post(name: HotkeyRecorderButton.hotkeyDidRecordNotification, object: self)
            }
        } else {
            NSSound.beep()
        }

        return true
    }

    private func handleWindowDidResignKeyNotification() {
        self.isRecording = false
    }

    override open func flagsChanged(with event: NSEvent) {
        if self.isRecording {
            let modifier: KeyboardModifier = KeyboardModifier(event).intersection([.commandKey, .controlKey, .optionKey, .shiftKey])
            self.modifier = modifier == [] ? nil : modifier
        }

        super.flagsChanged(with: event)
    }

    override open func viewWillMove(toWindow newWindow: NSWindow?) {
        if let oldWindow: NSWindow = self.window {
            self.windowNotificationObserver.remove(observee: oldWindow)
        }

        if let newWindow: NSWindow = newWindow {
            self.windowNotificationObserver.add(name: NSWindow.didResignKeyNotification, observee: newWindow, handler: { [weak self] in self?.handleWindowDidResignKeyNotification() })
        }
    }
}

extension NSMutableParagraphStyle
{
    fileprivate convenience init(alignment: NSTextAlignment) {
        self.init()
        self.alignment = alignment
    }
}