import Foundation
import CoreGraphics

/// Event observer provides a flexible interface for registering and managing multiple event handlers in, both, global
/// and local contexts.

open class EventObserver: AbstractObserver
{
    public convenience init(active: Bool) {
        self.init()
        self.activate(active)
    }

    // MARK: -

    open internal(set) var appKitDefinitions: [Handler.AppKit.Definition] = []
    open internal(set) var carbonDefinitions: [Handler.Carbon.Definition] = []

    internal func add(definition: Handler.AppKit.Definition) -> Self {
        self.appKitDefinitions.append(definition.activate(self.active))
        return self
    }

    internal func add(definition: Handler.Carbon.Definition) -> Self {
        self.carbonDefinitions.append(definition.activate(self.active))
        return self
    }

    internal func remove(definition: Handler.AppKit.Definition) -> Self {
        self.appKitDefinitions.enumerated().first(where: { $0.1 === definition }).map({ self.appKitDefinitions.remove(at: $0.0) })?.deactivate()
        return self
    }

    internal func remove(definition: Handler.Carbon.Definition) -> Self {
        self.carbonDefinitions.enumerated().first(where: { $0.1 === definition }).map({ self.appKitDefinitions.remove(at: $0.0) })?.deactivate()
        return self
    }

    // MARK: -

    override open var active: Bool {
        get { return super.active }
        set { self.activate(newValue) }
    }

    @discardableResult open func activate(_ newValue: Bool = true) -> Self {

        // Todo: we should use common store for all definitions where they would be kept in the order 
        // todo: of adding, so we can maintain that order during activation / deactivation.

        if newValue == self.active { return self }
        for definition in self.carbonDefinitions { definition.activate(newValue) }
        for definition in self.appKitDefinitions { definition.activate(newValue) }
        super.active = newValue
        return self
    }

    @discardableResult open func deactivate() -> Self {
        return self.activate(false)
    }
}

// MARK: - NSEvent

extension EventObserver
{
    @discardableResult open func add(mask: NSEvent.EventTypeMask, local: ((NSEvent) -> NSEvent?)?, global: ((NSEvent) -> ())?) -> Self {
        return self.add(definition: Handler.AppKit.Definition(
            mask: mask,
            handler: (global: global, local: local)))
    }

    /// Register AppKit local + global handler with automatic local event forwarding.
    @discardableResult open func add(mask: NSEvent.EventTypeMask, handler: @escaping () -> ()) -> Self {
        /*@formatter:off*/ return self.add(mask: mask, local: { handler(); return $0 }, global: { _ in handler() }) /*@formatter:on*/
    }

    /// Register AppKit local + global handler with automatic local event forwarding.
    @discardableResult open func add(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> Void) -> Self {
        /*@formatter:off*/ return self.add(mask: mask, local: { handler($0); return $0 }, global: handler) /*@formatter:on*/
    }

    /// Register AppKit local + global handler with manual local event forwarding.
    @discardableResult open func add(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent) -> NSEvent?) -> Self {
        /*@formatter:off*/ return self.add(mask: mask, local: handler, global: { _ = handler($0) }) /*@formatter:on*/
    }

    /// Register AppKit local handler with automatic event forwarding.
    @discardableResult open func add(mask: NSEvent.EventTypeMask, local: @escaping () -> ()) -> Self {
        /*@formatter:off*/ return self.add(mask: mask, local: { local(); return $0 }, global: nil) /*@formatter:on*/
    }

    /// Register AppKit local handler with automatic event forwarding.
    @discardableResult open func add(mask: NSEvent.EventTypeMask, local: @escaping (NSEvent) -> Void) -> Self {
        /*@formatter:off*/ return self.add(mask: mask, local: { local($0); return $0 }, global: nil) /*@formatter:on*/
    }

    /// Register AppKit local handler with manual event forwarding.
    @discardableResult open func add(mask: NSEvent.EventTypeMask, local: @escaping (NSEvent) -> NSEvent?) -> Self {
        /*@formatter:off*/ return self.add(mask: mask, local: local, global: nil) /*@formatter:on*/
    }

    /// Register AppKit global handler.
    @discardableResult open func add(mask: NSEvent.EventTypeMask, global: @escaping () -> ()) -> Self {
        /*@formatter:off*/ return self.add(mask: mask, local: nil, global: { _ in global() }) /*@formatter:on*/
    }

    /// Register AppKit global handler.
    @discardableResult open func add(mask: NSEvent.EventTypeMask, global: @escaping (NSEvent) -> Void) -> Self {
        /*@formatter:off*/ return self.add(mask: mask, local: nil, global: global) /*@formatter:on*/
    }

    /// Remove all handlers with specified mask.
    @discardableResult open func remove(mask: NSEvent.EventTypeMask) -> Self {
        self.appKitDefinitions.filter({ $0.mask == mask }).forEach({ _ = self.remove(definition: $0) })
        return self
    }
}

// MARK: - CGEvent

extension EventObserver
{
    @discardableResult open func add(mask: CGEventMask, location: CGEventTapLocation?, placement: CGEventTapPlacement?, options: CGEventTapOptions?, handler: @escaping (CGEvent) -> CGEvent?) -> Self {
        return Handler.Carbon.Definition(
            mask: mask,
            location: location ?? CGEventTapLocation.cgSessionEventTap,
            placement: placement ?? CGEventTapPlacement.headInsertEventTap,
            options: options ?? CGEventTapOptions.defaultTap,
            handler: handler).map({ self.add(definition: $0) }) ?? self
    }

    /// Register CoreGraphics handler with automatic event forwarding.
    @discardableResult open func add(mask: CGEventMask, handler: @escaping () -> ()) -> Self {
        /*@formatter:off*/ return self.add(mask: mask, handler: { handler(); return $0 } as Handler.Carbon.Signature) /*@formatter:on*/
    }

    /// Register CoreGraphics handler with automatic event forwarding.
    @discardableResult open func add(mask: CGEventMask, handler: @escaping (CGEvent) -> Void) -> Self {
        /*@formatter:off*/ return self.add(mask: mask, handler: { handler($0); return $0 } as Handler.Carbon.Signature) /*@formatter:on*/
    }

    /// Register CoreGraphics handler with manual event forwarding.
    @discardableResult open func add(mask: CGEventMask, handler: @escaping (CGEvent) -> CGEvent?) -> Self {
        /*@formatter:off*/ return self.add(mask: mask, location: nil, placement: nil, options: nil, handler: handler) /*@formatter:on*/
    }

    @discardableResult open func remove(mask: CGEventMask) -> Self {
        self.carbonDefinitions.filter({ $0.mask == mask }).forEach({ _ = self.remove(definition: $0) })
        return self
    }
}