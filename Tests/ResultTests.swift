//
//  ResultTests.swift
//  PhotosRxTests
//
//  Created by Rogerio de Paula Assis on 12/29/18.
//  Copyright © 2018 Tinybeans. All rights reserved.
//

import XCTest
@testable import PhotosRx

enum ResultTestError: Error {
    case testError
}

class ResultTests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testSuccess() {
        let result = Result<Int>.success(10)
        XCTAssertEqual(result.value, 10)
        XCTAssertNil(result.error)
        XCTAssertEqual(result.progress, 0)
        XCTAssertFalse(result.isProcessing)
        XCTAssertTrue(result.isSuccess)
    }

    func testError() {
        let result = Result<Int>.error(ResultTestError.testError)
        XCTAssertEqual(result.value, nil)
        guard let error = result.error, case ResultTestError.testError = error else {
            XCTFail("No error or incorrect error type found"); return
        }
        XCTAssertEqual(result.progress, 0)
        XCTAssertFalse(result.isProcessing)
        XCTAssertFalse(result.isSuccess)
    }

    func testIsProcessing() {
        let result = Result<Int>.processing(98)
        XCTAssertEqual(result.value, nil)
        XCTAssertNil(result.error)
        XCTAssertEqual(result.progress, 98)
        XCTAssertTrue(result.isProcessing)
        XCTAssertFalse(result.isSuccess)
    }

}
