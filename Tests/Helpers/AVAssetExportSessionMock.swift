//
//  AVAssetExportSessionMock.swift
//  PhotosRx
//
//  Created by Rogerio de Paula Assis on 12/31/18.
//  Copyright © 2018 Tinybeans. All rights reserved.
//

import Foundation
import Photos

// Mock used to test the Rx implementations
// of AVAssetExportSession methods
class AVAssetExportSessionMock: AVAssetExportSession {

    private var _status: AVAssetExportSession.Status = .unknown
    override var status: AVAssetExportSession.Status {
        return _status
    }

    private var _error: Error?
    override var error: Error? {
        return _error
    }

    private var _progress: Float = 0
    override var progress: Float {
        return _progress
    }

    private var event: PHImageManagerMockResponse?
    var imageRequestCancelled = false
    func enqueueResponse(with event: PHImageManagerMockResponse?) {
        self.event = event
    }

    override func determineCompatibleFileTypes(completionHandler handler: @escaping ([AVFileType]) -> Void) {
        guard let event = event else {
            handler([AVFileType.mov]);
            return
        }
        switch event {
        case .compatibleTypes(let types): handler(types)
        case _: handler([AVFileType.mov])
        }
    }

    override func exportAsynchronously(completionHandler handler: @escaping () -> Void) {
        guard let event = event else {
            handler();
            return
        }
        switch event {
        case .error(let e):
            _status = .failed
            _error = e
            handler()
        case .progress(let p):
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 5) {
                self._status = .exporting
                self._progress = p
                handler()
            }
        case .video:
            _status = .completed
            _progress = 1
            handler()
        case _:
            handler()
        }
    }

}
