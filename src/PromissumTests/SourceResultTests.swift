//
//  SourceResultTests.swift
//  Promissum
//
//  Created by Tom Lokhorst on 2015-02-08.
//  Copyright (c) 2015 Tom Lokhorst. All rights reserved.
//

import Foundation

import Foundation
import XCTest
import Promissum

class SourceResultTests: XCTestCase {

  func testResult() {
    var result: Result<Int>?

    let source = PromiseSource<Int>()
    let p = source.promise

    result = p.result()

    source.reject(NSError(domain: PromissumErrorDomain, code: 42, userInfo: nil))

    XCTAssert(result == nil, "Result should be nil")
  }

  func testResultValue() {
    var result: Result<Int>?

    let source = PromiseSource<Int>()
    let p = source.promise

    p.finallyResult { r in
      result = r
    }

    source.resolve(42)

    XCTAssert(result?.value() == 42, "Result should be value")
  }

  func testResultError() {
    var result: Result<Int>?

    let source = PromiseSource<Int>()
    let p = source.promise

    p.finallyResult { r in
      result = r
    }

    source.reject(NSError(domain: PromissumErrorDomain, code: 42, userInfo: nil))

    XCTAssert(result?.error()?.code == 42, "Result should be error")
  }

  func testResultMapError() {
    var value: Int?

    let source = PromiseSource<Int>()
    let p = source.promise
      .mapResult { result in
        switch result {
        case .Error(let error):
          return error.code + 1
        case .Value:
          return -1
        }
    }

    p.then { x in
      value = x
    }

    source.reject(NSError(domain: PromissumErrorDomain, code: 42, userInfo: nil))

    XCTAssert(value == 43, "Value should be set")
  }


  func testResultMapValue() {
    var value: Int?

    let source = PromiseSource<Int>()
    let p = source.promise
      .mapResult { result in
        switch result {
        case .Value(let boxed):
          let value = boxed.unbox
          return value + 1
        case .Error:
          return -1
        }
    }

    p.then { x in
      value = x
    }

    source.resolve(42)

    XCTAssert(value == 43, "Value should be set")
  }

  func testResultFlatMapValueValue() {
    var value: Int?

    let source = PromiseSource<Int>()
    let p = source.promise
      .flatMapResult { result in
        switch result {
        case .Value(let boxed):
          let value = boxed.unbox
          return Promise(value: value + 1)
        case .Error:
          return Promise(value: -1)
        }
    }

    p.then { x in
      value = x
    }

    source.resolve(42)

    XCTAssert(value == 43, "Value should be set")
  }

  func testResultFlatMapValueError() {
    var error: NSError?

    let source = PromiseSource<Int>()
    let p = source.promise
      .flatMapResult { result in
        switch result {
        case .Value(let boxed):
          let value = boxed.unbox
          return Promise(error: NSError(domain: PromissumErrorDomain, code: value + 1, userInfo: nil))
        case .Error:
          return Promise(value: -1)
        }
    }

    p.catch { e in
      error = e
    }

    source.resolve(42)

    XCTAssert(error?.code == 43, "Error should be set")
  }

  func testResultFlatMapErrorValue() {
    var value: Int?

    let source = PromiseSource<Int>()
    let p = source.promise
      .flatMapResult { result in
        switch result {
        case .Error(let error):
          return Promise(value: error.code + 1)
        case .Value:
          return Promise(value: -1)
        }
    }

    p.then { x in
      value = x
    }

    source.reject(NSError(domain: PromissumErrorDomain, code: 42, userInfo: nil))

    XCTAssert(value == 43, "Value should be set")
  }

  func testResultFlatMapErrorError() {
    var error: NSError?

    let source = PromiseSource<Int>()
    let p = source.promise
      .flatMapResult { result in
        switch result {
        case .Error(let error):
          return Promise(error: NSError(domain: PromissumErrorDomain, code: error.code + 1, userInfo: nil))
        case .Value:
          return Promise(value: -1)
        }
    }

    p.catch { e in
      error = e
    }

    source.reject(NSError(domain: PromissumErrorDomain, code: 42, userInfo: nil))

    XCTAssert(error?.code == 43, "Error should be set")
  }
}
