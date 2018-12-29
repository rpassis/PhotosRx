//
//  PHImageManager.swift
//  PhotosRx
//
//  Created by Rogerio de Paula Assis on 12/29/18.
//  Copyright © 2018 Tinybeans. All rights reserved.
//

import Foundation
import Photos
import RxSwift

fileprivate extension PHImageRequestOptions {
    static var defaultImageRequestOptions: PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.version = .current
        return options
    }
}

enum PHImageManagerError: Error {
    case imageFetchRequestFailed
    case videoFetchRequestFailed
//    case videoFetchRequestReturnedComposition(AVComposition)
//    case videoPlaybackRequestFailed
}

extension Reactive where Base: PHImageManager {

    typealias PHImageManagerImageResult = Result<UIImage>


    /// Requests the Photos framework for the backing image for a given PHAsset and options
    ///
    /// - Parameters:
    ///   - asset: the PHAsset for which the image is being requested
    ///   - targetSize: The desired targetSize
    ///   - contentMode: The desired contentMode
    ///   - options: The image request options
    /// - Returns:
    ///   A Result<UIImage, Error> specialized observable that can report
    ///   on progress, success and error.
    func image(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode = .default,
        options: PHImageRequestOptions = PHImageRequestOptions.defaultImageRequestOptions
    ) -> Observable<PHImageManagerImageResult> {

        return Observable.create { observer -> Disposable in
            // Progress report handler
            options.progressHandler = { progress, _, _, _ in
                observer.on(.next(.processing(Float(progress))))
            }
            
            let requestId = self.base.requestImage(
                for: asset,
                targetSize: targetSize,
                contentMode: contentMode,
                options: options) { (image, info) in
                    // If no image bail out
                    guard let image = image else {
                        let error = info?[PHImageErrorKey] as? Error ?? PHImageManagerError.imageFetchRequestFailed
                        observer.on(.next(.error(error)))
                        return
                    }
                    // Otherwise send a success event with the image
                    // Note that there is no guarantee this will be only called once
                    // as depending on the request options the Photos framework may
                    // first return an oportunistic, possibly degraded version of the image
                    // while the more expensive operation for a high quality image will continue
                    // in the background and send another onNext event with the image when done
                    observer.on(.next(.success(image)))
                    if
                        let isDegraded = info?[PHImageResultIsDegradedKey] as? Bool,
                        isDegraded == false {
                            // Here we check to see if the current image is degraded
                            // and in case not the work is done and we the observable will
                            // complete
                            observer.on(.completed)
                    }
            }

            // Cancel any current request on observable disposal
            return Disposables.create {
                self.base.cancelImageRequest(requestId)
            }
        }
    }
}

