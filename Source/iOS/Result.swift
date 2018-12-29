//
//  Result.swift
//  RxPhotos
//
//  Created by Rogerio de Paula Assis on 12/29/18.
//  Copyright © 2018 Tinybeans. All rights reserved.
//

import Foundation

enum Result<T> {
    case processing(Float)
    case success(T)
    case error(Error)

    var value: T? {
        if case .success(let t) = self {
            return t
        }
        return nil
    }

    var error: Error? {
        if case .error(let e) = self {
            return e
        }
        return nil
    }

    var isProcessing: Bool {
        if case .processing = self { return true }
        return false
    }

    var progress: Float {
        if case .processing(let p) = self { return p }
        return 0
    }

    var isSuccess: Bool {
        if case .success = self { return true }
        return false
    }

}
