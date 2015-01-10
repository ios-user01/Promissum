//
//  Promise.swift
//  Promissum
//
//  Created by Tom Lokhorst on 2014-10-11.
//  Copyright (c) 2014 Tom Lokhorst. All rights reserved.
//

import Foundation

public let PromissumErrorDomain = "com.nonstrict.Promissum"

public class Promise<T> {
  private(set) var state = State<T>.Unresolved
  private(set) var dispatch = DispatchMethod.Unspecified

  private var resolvedHandlers: [T -> Void] = []
  private var errorHandlers: [NSError -> Void] = []

  internal init() {
  }

  public init(value: T) {
    state = State<T>.Resolved(value)
  }

  public init(error: NSError) {
    state = State<T>.Rejected(error)
  }

  internal init(state: State<T>, dispatch: DispatchMethod) {
    self.state = state
    self.dispatch = dispatch
  }

  public func map<U>(transform: T -> U) -> Promise<U> {
    let source = PromiseSource<U>()

    let cont: T -> Void = { val in
      var transformedValue = transform(val)
      source.resolve(transformedValue)
    }

    addResolvedHandler(cont)
    addErrorHandler(source.reject)

    return source.promise
  }

  public func flatMap<U>(transform: T -> Promise<U>) -> Promise<U> {
    let source = PromiseSource<U>()

    let cont: T -> Void = { val in
      var transformedPromise = transform(val)
      transformedPromise
        .then(source.resolve)
        .catch(source.reject)
    }

    addResolvedHandler(cont)
    addErrorHandler(source.reject)

    return source.promise
  }

  public func then(handler: T -> Void) -> Promise<T> {
    addResolvedHandler(handler)

    return self
  }

  public func mapError(transform: NSError -> T) -> Promise<T> {
    let source = PromiseSource<T>()

    let cont: NSError -> Void = { error in
      var transformedValue = transform(error)
      source.resolve(transformedValue)
    }

    addErrorHandler(cont)
    addResolvedHandler(source.resolve)

    return source.promise
  }

  public func flatMapError(transform: NSError -> Promise<T>) -> Promise<T> {
    let source = PromiseSource<T>()

    let cont: NSError -> Void = { error in
      var transformedPromise = transform(error)
      transformedPromise
        .then(source.resolve)
        .catch(source.reject)
    }

    addErrorHandler(cont)
    addResolvedHandler(source.resolve)

    return source.promise
  }

  public func catch(continuation: NSError -> Void) -> Promise<T> {
    addErrorHandler(continuation)

    return self
  }

  public func finally(continuation: () -> Void) -> Promise<T> {
    addResolvedHandler({ _ in continuation() })
    addErrorHandler({ _ in continuation() })

    return self
  }

  private func addResolvedHandler(handler: T -> Void) {

    switch state {
    case State<T>.Unresolved:
      // Save handler for later
      resolvedHandlers.append(handler)

    case let State<T>.Resolved(getter):
      // Value is already available, call handler immediately
      let value = getter()
      callHandlers(value, handlers: [handler])

    case State<T>.Rejected:
      break;
    }
  }

  private func addErrorHandler(handler: NSError -> Void) {

    switch state {
    case State<T>.Unresolved:
      // Save handler for later
      errorHandlers.append(handler)

    case let State<T>.Rejected(error):
      // Error is already available, call handler immediately
      callHandlers(error, handlers: [handler])

    case State<T>.Resolved:
      break;
    }
  }

  private func executeResolvedHandlers(value: T) {

    // Call all previously scheduled handlers on correct queue
    callHandlers(value, handlers: resolvedHandlers)

    // Cleanup
    resolvedHandlers = []
    errorHandlers = []
  }

  private func executeErrorHandlers(error: NSError) {

    // Call all previously scheduled handlers on correct queue
    callHandlers(error, handlers: errorHandlers)

    // Cleanup
    resolvedHandlers = []
    errorHandlers = []
  }

  private func callHandlers<T>(arg: T, handlers: [T -> Void]) {
    switch dispatch {
    case .Unspecified:
      dispatch_async(dispatch_get_main_queue()) {
        for handler in handlers {
          handler(arg)
        }
      }
    case .Synchronous:
      for handler in handlers {
        handler(arg)
      }
    case let .OnQueue(queue):
      dispatch_async(queue) {
        for handler in handlers {
          handler(arg)
        }
      }
    }
  }

  public func value() -> T? {
    switch state {
    case State<T>.Resolved(let getter):
      let val = getter()
      return val
    default:
      return nil
    }
  }

  public func error() -> NSError? {
    switch state {
    case State<T>.Rejected(let error):
      return error
    default:
      return nil
    }
  }

  internal func tryResolve(value: T) -> Bool {
    switch state {
    case State<T>.Unresolved:
      state = State<T>.Resolved(value)

      executeResolvedHandlers(value)

      return true
    default:
      return false
    }
  }

  internal func tryReject(error: NSError) -> Bool {

    switch state {
    case State<T>.Unresolved:
      state = State<T>.Rejected(error)

      executeErrorHandlers(error)

      return true
    default:
      return false
    }
  }
}
