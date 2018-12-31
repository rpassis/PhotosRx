//
//  AVAssetExportSession+RxTests.swift
//  PhotosRxTests
//
//  Created by Rogerio de Paula Assis on 12/31/18.
//  Copyright © 2018 Tinybeans. All rights reserved.
//

import Foundation
import Photos
import XCTest
import RxTest
import RxSwift

@testable import PhotosRx

class AVAssetExportSession_RxTests: XCTestCase {

    var subject: AVAssetExportSessionMock!
    var scheduler: TestScheduler!
    var bag: DisposeBag!

    override func setUp() {
        scheduler = TestScheduler(initialClock: 0)
        let avAsset = AVURLAsset(url: URL(string: "https://me.com")!)
        subject = AVAssetExportSessionMock(asset: avAsset, presetName: AVAssetExportPresetHighestQuality)
        bag = DisposeBag()
    }

    func testDetermineCompatible_Fail() {

        let expectedTypes = PHImageManagerMockResponse.compatibleTypes([AVFileType.mov])
        subject.enqueueResponse(with: expectedTypes)
        let observer = scheduler.createObserver(Bool.self)
        subject.rx.determineCompatible(fileTypes: [AVFileType.ac3])
            .subscribe(observer)
            .disposed(by: bag)

        XCTAssertEqual(observer.events, [
            Recorded.next(0, false),
            Recorded.completed(0)
        ])
    }

    func testDetermineCompatible_Success() {

        let expectedTypes = PHImageManagerMockResponse.compatibleTypes([AVFileType.mov, AVFileType.ac3])
        subject.enqueueResponse(with: expectedTypes)
        let observer = scheduler.createObserver(Bool.self)
        subject.rx.determineCompatible(fileTypes: [AVFileType.ac3, AVFileType.mov])
            .subscribe(observer)
            .disposed(by: bag)

        XCTAssertEqual(observer.events, [
            Recorded.next(0, true),
            Recorded.completed(0)
        ])
    }

    func testExport_Success() {
        let url = URL(string: "https://google.com")!
        subject.enqueueResponse(with: PHImageManagerMockResponse.video(url))
        let observer = scheduler.createObserver(AVExportSessionStatusProgress.self)
        subject.rx.export()
            .subscribe(observer)
            .disposed(by: bag)

        let unwrappedEvents = observer.events.map { $0.value }.compactMap { $0 }
        let first = unwrappedEvents.first
        let last = unwrappedEvents.last
        if let firstEvent = first, case .next(let args) = firstEvent {
            let (status, progress) = args
            XCTAssertEqual(progress, 1)
            XCTAssertEqual(status, .completed)
        } else {
            XCTFail("Unexpected event found: \(String(describing: first))")
        }
        guard let lastEvent = last, case .completed = lastEvent else {
            XCTFail("Unexpected event found: \(String(describing: last))")
            return
        }
    }

    func testExport_Error() {
        let error = PHImageManagerMockError.mockError
        subject.enqueueResponse(with: PHImageManagerMockResponse.error(error))
        let observer = scheduler.createObserver(AVExportSessionStatusProgress.self)
        subject.rx.export()
            .subscribe(observer)
            .disposed(by: bag)

        let unwrappedEvents = observer.events.map { $0.value }.compactMap { $0 }
        XCTAssertEqual(unwrappedEvents.count, 1)
        guard let errorEvent = unwrappedEvents.first, case .error = errorEvent else {
            XCTFail("Unexpected event found: \(String(describing: unwrappedEvents.first))")
            return
        }
    }

}

