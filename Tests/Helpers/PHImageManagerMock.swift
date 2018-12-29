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
enum RequestImageResponse {
    case data
    case image(degraded: Bool)
    case error
    case progress(Float)
}

enum PHImageManagerMockError: Error {
    case mockError
}

class PHImageManagerMock: PHImageManager {

    private var events: [RequestImageResponse]?
    var imageRequestCancelled = false
    func enqueueResponse(with events: [RequestImageResponse]) {
        self.events = events
    }

    override func requestImage(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode,
        options: PHImageRequestOptions?,
        resultHandler: @escaping (UIImage?, [AnyHashable : Any]?) -> Void
    ) -> PHImageRequestID {
        events?.forEach({ event in
            switch event {
            case .image(let degraded):
                resultHandler(UIImage(), [PHImageResultIsDegradedKey: degraded])
            case .error:
                resultHandler(nil, [PHImageErrorKey: PHImageManagerMockError.mockError])
            case .progress(let progress):
                var flag: ObjCBool = false
                options?.progressHandler?(Double(progress), nil, &flag, nil)
            case _: break
            }
        })
        return PHImageRequestID(123)
    }

    override func requestImageData(
        for asset: PHAsset,
        options: PHImageRequestOptions?,
        resultHandler: @escaping (Data?, String?, UIImage.Orientation, [AnyHashable : Any]?) -> Void
    ) -> PHImageRequestID {
        events?.forEach({ event in
            switch event {
            case .data:
                resultHandler(Data(), nil, .up, nil)
            case .error:
                resultHandler(nil, nil, .up, [PHImageErrorKey: PHImageManagerMockError.mockError])
            case .progress(let progress):
                var flag: ObjCBool = false
                options?.progressHandler?(Double(progress), nil, &flag, nil)
            case _: break
            }
        })
        return PHImageRequestID(123)
    }
    override func cancelImageRequest(_ requestID: PHImageRequestID) {
        imageRequestCancelled = true
    }
}
