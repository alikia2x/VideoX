//
//  Observable.swift
//  VideoX
//
//  Created by Alikia2x on 2024/6/10.
//

import Foundation
class Helper: ObservableObject {
    @Published var isCompressing: Bool = false
    @Published var compressionProgress: Float = 0.0
    @Published var selectedMovive: Movie? = nil
    @Published var previewURL: URL? = nil
    @Published var calculatedBitrate: Int? = nil
    @Published var videoSize: CGSize? = nil
    @Published var videoLength: Double? = nil
}
