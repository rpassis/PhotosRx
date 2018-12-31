//
//  AVAssetExportSession+Rx.swift
//  PhotosRx
//
//  Created by Rogerio de Paula Assis on 12/31/18.
//  Copyright © 2018 Tinybeans. All rights reserved.
//

import Foundation
import RxSwift
import Photos

typealias AVExportSessionStatusProgress = (status: AVAssetExportSession.Status, progress: Float)

extension Reactive where Base: AVAssetExportSession {

    func determineCompatible(fileTypes desiredTypes: [AVFileType]) -> Observable<Bool> {
        return Observable.create { observer in
            self.base.determineCompatibleFileTypes(completionHandler: { compatibleTypes in
                let allCompatible = (desiredTypes.first(where: { compatibleTypes.contains($0) == false }) == nil)
                observer.on(.next(allCompatible))
                observer.on(.completed)
            })
            return Disposables.create()
        }
    }

    func export() -> Observable<AVExportSessionStatusProgress> {
        return Observable.create { observer -> Disposable in
            let exportSessionProgressUpdater = ExportSessionProgressUpdater(observer: observer)
            exportSessionProgressUpdater.session = self.base
            self.base.exportAsynchronously {
                switch self.base.status {
                case .exporting, .waiting, .unknown:
                    observer.on(.next((status: self.base.status, progress: self.base.progress)))
                case .completed, .cancelled:
                    observer.on(.next((status: self.base.status, progress: self.base.progress)))
                    observer.on(.completed)
                case .failed:
                    let error = self.base.error ?? PHImageManagerError.videoFetchRequestFailed
                    observer.on(.error(error))
                }
            }
            return Disposables.create {
                exportSessionProgressUpdater.session?.cancelExport()
                exportSessionProgressUpdater.session = nil
            }
        }
    }
}

fileprivate class ExportSessionProgressUpdater {

    private var timer: Timer?
    private let observer: AnyObserver<AVExportSessionStatusProgress>
    weak var session: AVAssetExportSession? {
        didSet { updateTimer() }
    }

    deinit {
        timer?.invalidate()
        print("timer dealloc'd")
    }

    init(observer: AnyObserver<AVExportSessionStatusProgress>) {
        self.observer = observer
    }

    private func updateTimer() {
        DispatchQueue.main.async { [weak self] in
            self?.timer?.invalidate()
            guard let session = self?.session else { return }
            self?.timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { [weak self] _ in
                let progress = session.progress
                self?.observer.on(.next((status: session.status, progress: progress)))
            })
        }
    }

}


