@testable import Observatory
import CoreGraphics
import Nimble
import XCTest

/*
Wow, this turned out to be a serious pain in the ass – testing events is not a joke… Doing it properly requires running 
a loop, as far as I understand there's no way testing global event dispatch, because, quoting, handler will not be called
for events that are sent to your own application. Instead, we check that observers sets everything up correctly.
*/
public class EventObserverTestCase: XCTestCase
{
    public func test() {
        let observer: EventObserver = EventObserver(active: true)

        try! observer.add(NSEventMask.AnyEventMask, global: true, local: true, handler: self.handler)
        expect(observer.definitions[0].handler.global).toNot(beNil())
        expect(observer.definitions[0].handler.local).toNot(beNil())
        expect(observer.definitions[0].monitor).toNot(beNil())

        try! observer.add(NSEventMask.AnyEventMask, global: true, local: false, handler: self.handler)
        expect(observer.definitions[1].handler.global).toNot(beNil())
        expect(observer.definitions[1].handler.local).to(beNil())
        expect(observer.definitions[1].monitor).toNot(beNil())

        try! observer.add(NSEventMask.AnyEventMask, global: false, local: true, handler: self.handler)
        expect(observer.definitions[2].handler.global).to(beNil())
        expect(observer.definitions[2].handler.local).toNot(beNil())
        expect(observer.definitions[2].monitor).toNot(beNil())

        try! observer.add(NSEventMask.AnyEventMask, handler: self.handler)
        expect(observer.definitions[3].handler.global).toNot(beNil())
        expect(observer.definitions[3].handler.local).toNot(beNil())
        expect(observer.definitions[3].monitor).toNot(beNil())

        observer.active = false

        expect(observer.definitions[0].monitor).to(beNil())
        expect(observer.definitions[1].monitor).to(beNil())
        expect(observer.definitions[2].monitor).to(beNil())
        expect(observer.definitions[3].monitor).to(beNil())

        observer.active = true

        expect(observer.definitions[0].monitor).toNot(beNil())
        expect(observer.definitions[1].monitor).toNot(beNil())
        expect(observer.definitions[2].monitor).toNot(beNil())
        expect(observer.definitions[3].monitor).toNot(beNil())
    }

    private func handler() {
        // Nothing here…
    }
}