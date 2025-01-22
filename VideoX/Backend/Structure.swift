import Foundation
import SwiftUI

struct Movie: Transferable {
    let url: URL

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(contentType: .movie) { movie in
            SentTransferredFile(movie.url)
        } importing: { received in
            let copy = URL.documentsDirectory.appending(path: "movie.mp4")

            if FileManager.default.fileExists(atPath: copy.path()) {
                try FileManager.default.removeItem(at: copy)
            }

            try FileManager.default.copyItem(at: received.file, to: copy)
            return Self.init(url: copy)
        }
    }
}

extension URL {
    static var documentsDirectory: URL {
        return FileManager.default.urls(
            for: .documentDirectory, in: .userDomainMask
        ).first!
    }
}


import Foundation
import CoreGraphics


// Long edge or short edge
enum LengthType {
    case long
    case short
    case original
}

struct ResolutionInfo {
    var type: LengthType
    var value: Int?
    init(type: LengthType, value: Int?) {
        self.type = type
        self.value = value
    }
}

enum Resolution {
    case resolution4K
    case resolution2K
    case resolution1080P
    case resolution720P
    case resolution540P
    case resolution480P
    case resolution360P
    case resolutionOriginal
    
    var info: ResolutionInfo {
        switch self {
        case .resolution4K:
            return ResolutionInfo(type: .long, value: 3840)
        case .resolution2K:
            return ResolutionInfo(type: .long, value: 2560)
        case .resolution1080P:
            return ResolutionInfo(type: .short, value: 1080)
        case .resolution720P:
            return ResolutionInfo(type: .short, value: 720)
        case .resolution540P:
            return ResolutionInfo(type: .short, value: 540)
        case .resolution480P:
            return ResolutionInfo(type: .short, value: 480)
        case .resolution360P:
            return ResolutionInfo(type: .short, value: 360)
        case .resolutionOriginal:
            return ResolutionInfo(type: .original, value: nil)
        }
    }
}

@MainActor
class Helper: ObservableObject {
    @Published var isCompressing: Bool = false
    @Published var compressionProgress: Float = 0.0
    @Published var selectedMovive: Movie? = nil
    @Published var previewURL: URL? = nil
    @Published var calculatedBitrate: Int? = nil
    @Published var videoSize: CGSize? = nil
    @Published var videoLength: Double? = nil
    @Published var targetResolution: Resolution = .resolutionOriginal
}
