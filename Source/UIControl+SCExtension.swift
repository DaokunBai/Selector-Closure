//
//  UIControl+Closures.swift
//  UIKit.Closures
//
//  Created by ray on 2017/12/19.
//  Copyright © 2017年 ray. All rights reserved.
//

import UIKit

extension UIControlEvents: Hashable {
    
    public var hashValue: Int {
        return self.rawValue.hashValue
    }
}

fileprivate typealias InvokersDicWrapper<T: UIControl> = DicWrapper<UIControlEvents, ArrayWrapper<Invoker<T>>>

fileprivate var invokersDicWrapperKey = 0

extension SCE where Element: UIControl {
    
    func invokers<T: UIControl>(forEvents events: UIControlEvents, createIfNotExist: Bool = true) -> ArrayWrapper<Invoker<T>>? {
        let dicWrapper: InvokersDicWrapper<T>? = self.getAttach(forKey: &invokersDicWrapperKey) ?? {
            if !createIfNotExist {
                return nil
            }
            let wrapper = InvokersDicWrapper<T>()
            self.set(wrapper, forKey: &invokersDicWrapperKey)
            return wrapper
            }()
        if nil == dicWrapper {
            return nil
        }
        let invokers: ArrayWrapper<Invoker<T>>? = dicWrapper!.dic[events] ?? {
            if !createIfNotExist {
                return nil
            }
            let invokers = ArrayWrapper<Invoker<T>>()
            dicWrapper!.dic[events] = invokers
            return invokers
            }()
        return invokers
    }
    
    public func add(_ events: UIControlEvents? = nil, _ closure: @escaping (Element) -> Void) -> Invoker<Element> {
        let control = self.object!
        let events: UIControlEvents! = events ?? {
                switch control {
                    case is UIButton: return .touchUpInside
                    case is UISwitch: fallthrough
                    case is UISlider: return .valueChanged
                    case is UITextField: return .editingChanged
                    default: return nil
                }
            }()
        assert(nil != events, "no default events for T")
        
        let wrapper: ArrayWrapper<Invoker<Element>> = invokers(forEvents: events)!
        let invoker = Invoker(control, closure)
        invoker.events = events
        wrapper.array.append(invoker)
        control.addTarget(invoker, action: invoker.action, for: events)
        return invoker
    }
    
    public func remove(_ invoker: Invoker<Element>) {
        let control = self.object!
        guard let dicWrapper: InvokersDicWrapper? = self.getAttach(forKey: &invokersDicWrapperKey),
            let events = invoker.events,
            let arrayWrapper = dicWrapper?.dic[events] else {
                return
        }
        for (idx, ivk) in arrayWrapper.array.enumerated() {
            if ivk === invoker {
                control.removeTarget(invoker, action: invoker.action, for: events)
                arrayWrapper.array.remove(at: idx)
                break
            }
        }
    }
    
    public func removeAll(for events: UIControlEvents) {
        let control = self.object!
        guard let wrapper = invokers(forEvents: events, createIfNotExist: false) else {
            return
        }
        for invoker in wrapper.array {
            control.removeTarget(invoker, action: invoker.action, for: events)
        }
        wrapper.array.removeAll()
    }
    
    public func didAdd(_ events: UIControlEvents) -> Bool {
        guard let wrapper = invokers(forEvents: events, createIfNotExist: false) else {
            return false
        }
        return wrapper.array.count > 0
    }
}

