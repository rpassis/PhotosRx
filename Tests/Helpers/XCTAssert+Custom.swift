//
//  XCTAssert+Custom.swift
//  PhotosRxTests
//
//  Created by Rogerio de Paula Assis on 12/30/18.
//  Copyright © 2018 Tinybeans. All rights reserved.
//

import Foundation
import XCTest
import RxSwift
@testable import PhotosRx

func XCTAssertEqual<T>(
    _ enqueuedEvent: PHImageManagerMockResponse, _ receivedEvents: [Event<Result<T>>],
    file: StaticString = #file, line: UInt = #line) {
    switch enqueuedEvent {
    case .data(let d):
        if
            let dataEvent = receivedEvents.first?.element,
            case .success(let data) = dataEvent {
            XCTAssertEqual(data as? Data, d, file: file, line: line)
        } else {
            XCTFail("Incorrect Result event found, .success<Data> expected", file: file, line: line)
        }

    case .image(let i, let degraded):
        let expectedCount = degraded ? 1 : 2
        XCTAssertEqual(receivedEvents.count, expectedCount, file: file, line: line)
        if
            let dataEvent = receivedEvents.first?.element,
            case .success(let image) = dataEvent {
            XCTAssertEqual(image as? UIImage, i, file: file, line: line)
        } else {
            XCTFail("Incorrect Result event found, .success<UIImage> expected", file: file, line: line)
        }
        if degraded == false {
            guard let lastEvent = receivedEvents.last, case .completed = lastEvent else {
                XCTFail("Incorrect Result event found, .completed expected", file: file, line: line)
                return
            }
        }

    case .video(let u):
        XCTAssertEqual(receivedEvents.count, 2, file: file, line: line)
        if
            let event = receivedEvents.first?.element,
            case .success(let url) = event {
            XCTAssertEqual(url as? URL, u, file: file, line: line)
        } else {
            XCTFail("Incorrect Result event found, .success<URL> expected", file: file, line: line)
        }        

    case .error:
        XCTAssertEqual(receivedEvents.count, 2, file: file, line: line)
        guard
            let event = receivedEvents.first?.element,
            case .error = event else {
            XCTFail("Incorrect Result event found \(receivedEvents.first), .error expected", file: file, line: line)
            return
        }
        guard let lastEvent = receivedEvents.last, case .completed = lastEvent else {
            XCTFail("Incorrect Result event: found \(receivedEvents.last), .completed expected", file: file, line: line)
            return
        }

    case .progress(let float):
        XCTAssertEqual(receivedEvents.count, 1, file: file, line: line)
        if let event = receivedEvents.first?.element, case .processing(let f) = event {
            XCTAssertEqual(float, f, file: file, line: line)
        } else {
            XCTFail("Incorrect Result event found, .processing expected", file: file, line: line)
        }
    }
}
