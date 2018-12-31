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
    static var `default`: PHImageRequestOptions {
        let options = PHImageRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.version = .current
        return options
    }
}

fileprivate extension PHVideoRequestOptions {
    static var `default`: PHVideoRequestOptions {
        let options = PHVideoRequestOptions()
        options.isNetworkAccessAllowed = true
        options.deliveryMode = .highQualityFormat
        options.version = .current
        return options
    }
}

enum PHImageManagerError: Error {
    case imageFetchRequestFailed
    case videoFetchRequestFailed
    case unsupportedVideoFormat
//    case videoFetchRequestReturnedComposition(AVComposition)
//    case videoPlaybackRequestFailed
}

typealias PHImageManagerImageResult = Result<UIImage>
typealias PHImageManagerDataResult  = Result<Data>
typealias PHImageManagerURLResult   = Result<URL>

extension Reactive where Base: PHImageManager {

    /// Requests the Photos framework for the backing image for a given PHAsset and options
    ///
    /// - Parameters:
    ///   - asset: the PHAsset for which the image is being requested
    ///   - targetSize: The desired targetSize
    ///   - contentMode: The desired contentMode
    ///   - options: The image request options
    /// - Returns:
    ///   A Result<UIImage> specialized observable that can report
    ///   on progress, success and error.
    func image(
        for asset: PHAsset,
        targetSize: CGSize,
        contentMode: PHImageContentMode = .default,
        options: PHImageRequestOptions = PHImageRequestOptions.default
    ) -> Observable<PHImageManagerImageResult> {

        return Observable.create { observer -> Disposable in
            // Progress report handler
            options.progressHandler = { progress, error, _, _ in
                if let error = error {
                    observer.on(.next(.error(error)))
                    observer.on(.completed)
                    return
                }
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
                        observer.on(.completed)
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


    /// Requests the Photos framework for the backing data blob for a given PHAsset and options
    ///
    /// - Parameters:
    ///   - asset: the PHAsset for which the data is being requested
    ///   - options: The image request options
    /// - Returns:
    ///   A Result<Data> specialized observable that can report
    ///   on progress, success and error.
    func data(
        for asset: PHAsset,
        options: PHImageRequestOptions = PHImageRequestOptions.default
        ) -> Observable<PHImageManagerDataResult> {
        return Observable.create { observer -> Disposable in
            // Progress report handler
            options.progressHandler = { progress, error, _, _ in
                if let error = error {
                    observer.on(.next(.error(error)))
                    observer.on(.completed)
                    return
                }
                observer.on(.next(.processing(Float(progress))))
            }
            let requestId = self.base.requestImageData(
                for: asset,
                options: options,
                resultHandler: { (data, imageUTI, imageOrientation, info) in
                    guard let data = data else {
                        let error = info?[PHImageErrorKey] as? Error ?? PHImageManagerError.imageFetchRequestFailed
                        observer.on(.next(.error(error)))
                        observer.on(.completed)
                        return
                    }
                    observer.on(.next(.success(data)))
                    observer.on(.completed)
            })
            return Disposables.create {
                self.base.cancelImageRequest(requestId)
            }
        }
    }
}

extension Reactive where Base: PHImageManager {

    func exportVideo(
        for asset: PHAsset,
        options: PHVideoRequestOptions = PHVideoRequestOptions.default,
        exportPreset: String = AVAssetExportPresetHighestQuality,
        destination url: URL) -> Observable<PHImageManagerURLResult> {
        return Observable.create({ observer -> Disposable in
            options.progressHandler = { progress, error, _, _ in
                if let error = error {
                    observer.on(.next(.error(error)))
                    observer.on(.completed)
                    return
                }
                observer.on(.next(.processing(Float(progress))))
            }
            let exportSessionProgressUpdater = ExportSessionProgressUpdater(observer: observer)
            let requestId = self.base.requestExportSession(
                forVideo: asset,
                options: options,
                exportPreset: exportPreset,
                resultHandler: { (session, info) in
                    guard let session = session else {
                        let error = PHImageManagerError.videoFetchRequestFailed
                        observer.on(.next(.error(error)));
                        observer.on(.completed)
                        return
                    }
                    exportSessionProgressUpdater.session = session
                    if let error = info?[PHImageErrorKey] as? Error {
                        observer.on(.next(.error(error)));
                        observer.on(.completed)
                        return
                    }
                    session.outputURL = url
                    session.determineCompatibleFileTypes(completionHandler: { fileTypes in
                        guard fileTypes.contains(AVFileType.mov) else {
                            let error = PHImageManagerError.unsupportedVideoFormat
                            observer.on(.next(.error(error)));
                            observer.on(.completed)
                            return
                        }
                        session.exportAsynchronously {
                            switch session.status {
                            case .completed:
                                observer.on(.next(.success(url)))
                                observer.on(.completed)
                            case .waiting, .exporting:
                                let progress = session.progress
                                observer.on(.next(.processing(progress)))
                            case .failed, .cancelled:
                                let error = session.error ?? PHImageManagerError.videoFetchRequestFailed
                                observer.on(.next(.error(error)))
                                observer.on(.completed)
                            case .unknown:
                                break
                            }
                        }
                    })
            })

            return Disposables.create {
                exportSessionProgressUpdater.session?.cancelExport()
                exportSessionProgressUpdater.session = nil
                self.base.cancelImageRequest(requestId)
            }
        })
    }
}

fileprivate class ExportSessionProgressUpdater {

    private var timer: Timer?
    private let observer: AnyObserver<PHImageManagerURLResult>
    weak var session: AVAssetExportSession? {
        didSet { updateTimer() }
    }

    deinit {
        timer?.invalidate()
        print("timer dealloc'd")
    }

    init(observer: AnyObserver<PHImageManagerURLResult>) {
        self.observer = observer
    }

    private func updateTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.timer?.invalidate()
            guard let session = self?.session else { return }
            self?.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
                let progress = session.progress
                self?.observer.on(.next(.processing(progress)))
            })
        }
    }

}
