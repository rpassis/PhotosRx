//
//  PHImageManagerMock.swift
//  PhotosRx
//
//  Created by Rogerio de Paula Assis on 12/29/18.
//  Copyright © 2018 Tinybeans. All rights reserved.
//

import Foundation
import Photos
@testable import PhotosRx

// Use to enqueue response events
// with PHImageManagerMock
enum PHImageManagerMockResponse {
    case data(Data)
    case error(Error)
    case image(UIImage, degraded: Bool)
    case progress(Float)
    case video(URL)
    case compatibleTypes([AVFileType])
}

enum PHImageManagerMockError: Error {
    case mockError
}

class PHImageManagerMock: PHImageManager {

    private var event: PHImageManagerMockResponse?
    var requestCancelled = false
    func enqueueResponse(with event: PHImageManagerMockResponse?) {
        self.event = event
    }

    deinit {
        print("Mock dealloc'd")
    }

    override func requestImage(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        options: PHImageRequestOptions?,
        resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void
    ) -> PHImageRequestID {
        if let event = event {
            switch event {
            case .image(let image, let degraded):
                resultHandler(image, [PHImageResultIsDegradedKey: degraded])
            case .error(let e):
                resultHandler(nil, [PHImageErrorKey: e])
            case .progress(let progress):
                var flag: ObjCBool = false
                options?.progressHandler?(Double(progress), nil, &flag, nil)
            case _: break
            }
        }
        return PHImageRequestID(123)
    }

    override func requestImageData(
        for asset: PHAsset,
        options: PHImageRequestOptions?,
        resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable : Any]?) -> Void
    ) -> PHImageRequestID {
        if let event = event {
            switch event {
            case .data(let d):
                resultHandler(d, nil, .up, nil)
            case .error(let e):
                resultHandler(nil, nil, .up, [PHImageErrorKey: e])
            case .progress(let progress):
                var flag: ObjCBool = false
                options?.progressHandler?(Double(progress), nil, &flag, nil)
            case _: break
            }
        }
        return PHImageRequestID(123)
    }

    override func cancelImageRequest(_ requestID: PHImageRequestID) {
        requestCancelled = true
    }

    override func requestExportSession(
        forVideo asset: PHAsset,
        options: PHVideoRequestOptions?,
        exportPreset: String,
        resultHandler: @escaping (AVAssetExportSession?, [AnyHashable : Any]?) -> Void) -> PHImageRequestID {
        let url = URL(string: "https://google.com")!
        let avAsset = AVURLAsset(url: url)
        let session = AVAssetExportSessionMock(asset: avAsset, presetName: exportPreset)
        let info: [String: Any] = {
            if let event = event, case .error(let e) = event { return [PHImageErrorKey: e] }
            return [:]
        }()
        session?.enqueueResponse(with: event)
        resultHandler(session, info)
        return PHImageRequestID(123)
    }
}
