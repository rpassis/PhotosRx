//
//  PHImageManager+RxTests.swift
//  PhotosRxTests
//
//  Created by Rogerio de Paula Assis on 12/29/18.
//  Copyright © 2018 Tinybeans. All rights reserved.
//

import XCTest
import Photos
import RxSwift
import RxTest
@testable import PhotosRx

class PHImageManager_RxTests: XCTestCase {

    var subject: PHImageManagerMock!
    var scheduler: TestScheduler!
    var bag: DisposeBag!

    override func setUp() {
        scheduler = TestScheduler(initialClock: 0)
        subject = PHImageManagerMock()
        bag = DisposeBag()
    }

    override func tearDown() {}

    func testFetchImageForSize_Error() {
        let asset = PHAsset()
        let size = CGSize.zero
        // Given the enqueued mock responses
        subject.enqueueResponse(with: [
            .error,
            .image(degraded: true)
        ])
        // When
        let observer = scheduler.createObserver(Result<UIImage>.self)
        subject.rx.image(for: asset, targetSize: size)
            .subscribe(observer)
            .disposed(by: bag)

        // Then
        XCTAssertEqual(observer.events.count, 2)
        guard
            let errorEvent = observer.events.first?.value.element,
            case .error = errorEvent else {
                XCTFail("Unable to find error event")
                return
        }
    }

    func testFetchImageForSize_Success() {
        let asset = PHAsset()
        let size = CGSize.zero
        // Given the enqueued mock responses
        subject.enqueueResponse(with: [
            .image(degraded: true),
            .image(degraded: true),
            .image(degraded: false) // will complete so + 1 event
        ])
        // When
        let observer = scheduler.createObserver(Result<UIImage>.self)
        subject.rx.image(for: asset, targetSize: size)
            .subscribe(observer)
            .disposed(by: bag)

        // Then
        XCTAssertEqual(observer.events.count, 4)
        guard
            let event = observer.events.last?.value,
            case .completed = event else {
                XCTFail("Unable to find completed event")
                return
        }
        
    }

    func testFetchImageForSize_Progress() {
        let asset = PHAsset()
        let size = CGSize.zero
        // Given the enqueued mock responses
        subject.enqueueResponse(with: [
            .progress(10),
            .progress(20),
            .progress(30)
        ])
        // When
        let observer = scheduler.createObserver(Result<UIImage>.self)
        subject.rx.image(for: asset, targetSize: size)
            .subscribe(observer)
            .disposed(by: bag)

        // Then
        XCTAssertEqual(observer.events.count, 3)
        guard
            let event = observer.events.last?.value.element,
            case .processing(let p) = event, p == 30 else {
                XCTFail("Unable to find completed event")
                return
        }
    }

    func testRequestCancelledOnDispose() {
        let asset = PHAsset()
        let size = CGSize.zero
        // Given the enqueued mock responses
        // When
        let observer = scheduler.createObserver(Result<UIImage>.self)
        let disposable = subject.rx
            .image(for: asset, targetSize: size)
            .subscribe(observer)
        XCTAssertFalse(subject.imageRequestCancelled)
        disposable.dispose()
        XCTAssertTrue(subject.imageRequestCancelled)
    }
}

extension PHImageManager_RxTests {

    func testRequestData_Success() {
        let asset = PHAsset()
        // Given the enqueued mock responses
        subject.enqueueResponse(with: [
            .progress(10),
            .progress(20),
            .data
        ])
        // When
        let observer = scheduler.createObserver(Result<Data>.self)
        subject.rx.data(for: asset)
            .subscribe(observer)
            .disposed(by: bag)

        // Then
        XCTAssertEqual(observer.events.count, 4)
        guard
            let event = observer.events.last?.value,
            case .completed = event else {
                XCTFail("Unable to find completed event")
                return
        }
    }

    func testRequestData_Error() {
        let asset = PHAsset()
        // Given the enqueued mock responses
        subject.enqueueResponse(with: [
            .progress(10),
            .progress(20),
            .error
        ])
        // When
        let observer = scheduler.createObserver(Result<Data>.self)
        subject.rx.data(for: asset)
            .subscribe(observer)
            .disposed(by: bag)

        // Then
        XCTAssertEqual(observer.events.count, 3)
        guard
            let event = observer.events.last?.value.element,
            case .error = event else {
                XCTFail("Unable to find error event")
                return
        }
    }

    func testRequestData_Progress() {
        let asset = PHAsset()
        let size = CGSize.zero
        // Given the enqueued mock responses
        subject.enqueueResponse(with: [
            .progress(10),
            .progress(20),
            .progress(30)
        ])
        // When
        let observer = scheduler.createObserver(Result<UIImage>.self)
        subject.rx.image(for: asset, targetSize: size)
            .subscribe(observer)
            .disposed(by: bag)

        // Then
        XCTAssertEqual(observer.events.count, 3)
        guard
            let event = observer.events.last?.value.element,
            case .processing(let p) = event, p == 30 else {
                XCTFail("Unable to find completed event")
                return
        }
    }


    func testDataRequestCancelledOnDispose() {
        let asset = PHAsset()
        // When
        let observer = scheduler.createObserver(Result<Data>.self)
        let disposable = subject.rx
            .data(for: asset)
            .subscribe(observer)
        XCTAssertFalse(subject.imageRequestCancelled)
        disposable.dispose()
        XCTAssertTrue(subject.imageRequestCancelled)
    }
    
}
