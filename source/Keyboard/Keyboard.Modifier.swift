import AppKit.NSEvent
import Carbon

/// Check source for comments, some keys are not available on Mac OS X.

public struct KeyboardModifier: RawRepresentable, OptionSet
{
    public init(rawValue: Int) { self.rawValue = rawValue }
    public init(_ rawValue: Int) { self.init(rawValue: rawValue) }
    public init(_ event: NSEvent) { self.init(event.modifierFlags) }

    public init(_ flags: NSEvent.ModifierFlags) {
        var rawValue: Int = 0

        // I'll leave this as a reminder for future generation. Apparently, if you used to deal with CoreGraphics you'd know 
        // what the fuck modifier flags are made or you are doomed, otherwise. And made of it is from CoreGraphics event 
        // source flags state, or `CGEventSource.flagsState(.hidSystemState)` to be precise. So, an empty flags will have 
        // raw value not of `0` but of `UInt(CGEventSource.flagsState(.hidSystemState).rawValue)`…

        if flags.rawValue & NSEvent.ModifierFlags.deviceIndependentFlagsMask.rawValue != 0 {
            if flags.contains(.capsLock) { rawValue |= Carbon.alphaLock }
            if flags.contains(.option) { rawValue |= Carbon.optionKey }
            if flags.contains(.command) { rawValue |= Carbon.cmdKey }
            if flags.contains(.control) { rawValue |= Carbon.controlKey }
            if flags.contains(.shift) { rawValue |= Carbon.shiftKey }
        }

        self = KeyboardModifier(rawValue: rawValue)
    }

    public let rawValue: Int

    // MARK: -

    public static let none = KeyboardModifier(rawValue: 0)
    public static let capsLockKey = KeyboardModifier(rawValue: Carbon.alphaLock)
    public static let commandKey = KeyboardModifier(rawValue: Carbon.cmdKey)
    public static let controlKey = KeyboardModifier(rawValue: Carbon.controlKey)
    public static let optionKey = KeyboardModifier(rawValue: Carbon.optionKey)
    public static let shiftKey = KeyboardModifier(rawValue: Carbon.shiftKey)

    // MARK: -

    public var name: String? {
        var string: String = ""

        if self.contains(.capsLockKey) { string += "⇪" }
        if self.contains(.commandKey) { string += "⌘" }
        if self.contains(.controlKey) { string += "⌃" }
        if self.contains(.optionKey) { string += "⌥" }
        if self.contains(.shiftKey) { string += "⇧" }

        return string == "" ? nil : string
    }
}

extension KeyboardModifier: Equatable, Hashable
{
    public var hashValue: Int { return Int(self.rawValue) }
}

extension KeyboardModifier: CustomStringConvertible
{
    public var description: String {
        return self.name ?? ""
    }
}