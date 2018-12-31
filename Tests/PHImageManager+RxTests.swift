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

    override func tearDown() {
        subject = nil
    }

    func testFetchImageForSize_Error() {
        let asset = PHAsset()
        let size = CGSize.zero
        // Given the enqueued mock responses
        subject.enqueueResponse(with: .error(PHImageManagerMockError.mockError))

        // When
        let observer = scheduler.createObserver(Result<UIImage>.self)
        subject.rx.image(for: asset, targetSize: size)
            .subscribe(observer)
            .disposed(by: bag)

        // Then the sequence should emit an onNext(error) and then complete
        let events = observer.events.map { $0.value }
        XCTAssertEqual(.error(PHImageManagerMockError.mockError), events)
    }

    func testFetchImageForSize_Success() {
        let asset = PHAsset()
        let size = CGSize.zero
        let image = UIImage()
        let observer = scheduler.createObserver(Result<UIImage>.self)

        // Given an enqueued response of an image that is degraded
        subject.enqueueResponse(with: .image(image, degraded: true))

        // When
        subject.rx.image(for: asset, targetSize: size)
            .subscribe(observer)
            .disposed(by: bag)

        // Then I expect to receive the image but that the observer will stay connected/not complete
        let events = observer.events.map { $0.value }
        XCTAssertEqual(.image(image, degraded: true), events)

        // Given an enqueued response of an image that is no degraded
        let moreObserver = scheduler.createObserver(Result<UIImage>.self)
        subject.enqueueResponse(with: .image(image, degraded: false))

        // When
        subject.rx.image(for: asset, targetSize: size)
            .subscribe(moreObserver)
            .disposed(by: bag)

        // Then I expect to receive the non degraded image and the observer to complete
        let moreEvents = moreObserver.events.map { $0.value }
        XCTAssertEqual(.image(image, degraded: false), moreEvents)
    }

    func testFetchImageForSize_Progress() {
        let asset = PHAsset()
        let size = CGSize.zero
        // Given the enqueued mock responses
        subject.enqueueResponse(with: .progress(10))

        // When
        let observer = scheduler.createObserver(Result<UIImage>.self)
        subject.rx.image(for: asset, targetSize: size)
            .subscribe(observer)
            .disposed(by: bag)

        // Then
        XCTAssertEqual(.progress(10), [Event.next(Result<UIImage>.processing(10))])
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
        subject.enqueueResponse(with: .progress(99.99))

        // When
        let observer = scheduler.createObserver(Result<Data>.self)
        subject.rx.data(for: asset)
            .subscribe(observer)
            .disposed(by: bag)

        // Then
        XCTAssertEqual(.progress(99.99), [Event.next(Result<UIImage>.processing(99.99))])
    }

    func testRequestData_Error() {
        let asset = PHAsset()
        // Given the enqueued mock responses
        subject.enqueueResponse(with: .error(PHImageManagerMockError.mockError))

        // When
        let observer = scheduler.createObserver(Result<Data>.self)
        subject.rx.data(for: asset)
            .subscribe(observer)
            .disposed(by: bag)

        // Then
        let events = observer.events.map { $0.value }
        XCTAssertEqual(.error(PHImageManagerMockError.mockError), events)
    }

    func testRequestData_Progress() {
        let asset = PHAsset()
        let size = CGSize.zero
        // Given the enqueued mock responses
        subject.enqueueResponse(with: .progress(10))
        // When
        let observer = scheduler.createObserver(Result<UIImage>.self)
        subject.rx.image(for: asset, targetSize: size)
            .subscribe(observer)
            .disposed(by: bag)

        // Then
        let events = observer.events.map { $0.value }
        XCTAssertEqual(.progress(10), events)
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

extension PHImageManager_RxTests {

    func testVideoDownload_Success() {
        let asset = PHAsset()
        let url = URL(string: "https://google.com")!
        subject.enqueueResponse(with: .video(url))
        let observer = scheduler.createObserver(Result<URL>.self)

        // When
        subject.rx
            .exportVideo(for: asset, destination: url)
            .subscribe(observer)
            .disposed(by: bag)

        // Then
        let events = observer.events.map { $0.value }
        XCTAssertEqual(.video(url), events)
    }

    func testVideoDownload_Error() {
        let asset = PHAsset()
        let url = URL(string: "https://google.com")!
        subject.enqueueResponse(with: .error(PHImageManagerMockError.mockError))
        let observer = scheduler.createObserver(Result<URL>.self)

        // When
        subject.rx
            .exportVideo(for: asset, destination: url)
            .subscribe(observer)
            .disposed(by: bag)

        // Then
        let events = observer.events.map { $0.value }
        XCTAssertEqual(.error(PHImageManagerMockError.mockError), events)
    }

    func testVideoDownload_Progress() {
        let asset = PHAsset()
        let url = URL(string: "https://google.com")!
        subject.enqueueResponse(with: .progress(999))
        let observer = scheduler.createObserver(Result<URL>.self)

        // When
        let expectation = self.expectation(description: "progress timer")
        subject.rx
            .exportVideo(for: asset, destination: url)
            .do(onNext: { r in
                // This will be called multiple times so
                // we need to make sure we are fulfilling
                // the expectation for the correct event
                if case .processing(let p) = r, p == 999 {
                    expectation.fulfill()
                }
            })
            .subscribe(observer)
            .disposed(by: bag)

        // Then
        waitForExpectations(timeout: 10, handler: nil)

        let events = observer.events
        XCTAssertEqual(events.count, 6)
        XCTAssertEqual(.progress(999), [events.last?.value].compactMap { $0 })
    }

}
