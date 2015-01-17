//
//  WhenTests.swift
//  Promissum
//
//  Created by Tom Lokhorst on 2015-01-07.
//  Copyright (c) 2015 Tom Lokhorst. All rights reserved.
//

import Foundation
import XCTest
import Promissum

class WhenTests: XCTestCase {

  func testBothValue() {
    var value: Int?

    let source1 = PromiseSource<Int>()
    let source2 = PromiseSource<Int>()
    let p1 = source1.promise
    let p2 = source2.promise

    let p = whenBoth(p1, p2)
      .then { (x, y) in
        value = x + y
    }

    source1.resolve(40)
    source2.resolve(2)

    // Check assertions
    let expectation = expectationWithDescription("Promise didn't finish")
    p.finally {
      XCTAssert(value == 42, "Value should be 42")
      expectation.fulfill()
    }

    waitForExpectationsWithTimeout(0.03, handler: nil)
  }

  func testBothError() {
    var error: Int?

    let source1 = PromiseSource<Int>()
    let source2 = PromiseSource<Int>()
    let p1 = source1.promise
    let p2 = source2.promise

    let p = whenBoth(p1, p2)
      .catch { e in
        error = e.code
      }

    source1.resolve(40)
    source2.reject(NSError(domain: PromissumErrorDomain, code: 42, userInfo: nil))

    // Check assertions
    let expectation = expectationWithDescription("Promise didn't finish")
    p.finally {
      XCTAssert(error == 42, "Error should be 42")
      expectation.fulfill()
    }

    waitForExpectationsWithTimeout(0.03, handler: nil)
  }

  func testEitherLeft() {
    var value: Int?

    let source1 = PromiseSource<Int>()
    let source2 = PromiseSource<Int>()
    let p1 = source1.promise
    let p2 = source2.promise

    let p = whenEither(p1, p2)
      .then { x in
        value = x
      }
      .catch { e in
        value = e.code
      }

    source1.resolve(1)
    source2.reject(NSError(domain: PromissumErrorDomain, code: 2, userInfo: nil))

    // Check assertions
    let expectation = expectationWithDescription("Promise didn't finish")
    p.finally {
      XCTAssert(value == 1, "Value should be 1")
      expectation.fulfill()
    }

    waitForExpectationsWithTimeout(0.03, handler: nil)
  }

  func testEitherRight() {
    var value: Int?

    let source1 = PromiseSource<Int>()
    let source2 = PromiseSource<Int>()
    let p1 = source1.promise
    let p2 = source2.promise

    let p = whenEither(p1, p2)
      .then { x in
        value = x
      }
      .catch { e in
        value = e.code
      }

    source1.reject(NSError(domain: PromissumErrorDomain, code: 1, userInfo: nil))
    source2.resolve(2)

    // Check assertions
    let expectation = expectationWithDescription("Promise didn't finish")
    p.finally {
      XCTAssert(value == 2, "Value should be 2")
      expectation.fulfill()
    }

    waitForExpectationsWithTimeout(0.03, handler: nil)
  }

  func testEitherError() {
    var value: Int?

    let source1 = PromiseSource<Int>()
    let source2 = PromiseSource<Int>()
    let p1 = source1.promise
    let p2 = source2.promise

    let p = whenEither(p1, p2)
      .then { x in
        value = x
      }
      .catch { e in
        value = e.code
      }

    source1.reject(NSError(domain: PromissumErrorDomain, code: 1, userInfo: nil))
    source2.reject(NSError(domain: PromissumErrorDomain, code: 2, userInfo: nil))

    // Check assertions
    let expectation = expectationWithDescription("Promise didn't finish")
    p.finally {
      XCTAssert(value == 2, "Value should be 2")
      expectation.fulfill()
    }

    waitForExpectationsWithTimeout(0.03, handler: nil)
  }
}
