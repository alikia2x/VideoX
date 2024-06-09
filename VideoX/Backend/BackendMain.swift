//
//  main.swift
//  VideoX
//
//  Created by Alikia2x on 2024/6/10.
//

import Foundation
import AVFoundation
import Photos
import AVKit
import PhotosUI
import SwiftUI

func compressVideo(inputURL: URL, helper: Helper) {
    let asset = AVAsset(url: inputURL)
    guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPresetMediumQuality) else {
        print("Failed to create export session.")
        return
    }
    let outputURL = URL.documentsDirectory.appending(path: "compressed.mp4")

    if FileManager.default.fileExists(atPath: outputURL.path) {
        do {
            try FileManager.default.removeItem(at: outputURL)
        } catch {
            print("Error removing existing file: \(error.localizedDescription)")
            return
        }
    }

    exportSession.outputURL = outputURL
    exportSession.outputFileType = .mp4
    
    helper.isCompressing = true
    helper.compressionProgress = 0.0

    exportSession.exportAsynchronously {
        DispatchQueue.main.async {
            helper.isCompressing = false
            switch exportSession.status {
            case .completed:
                helper.previewURL = outputURL
                saveToPhotoLibrary(outputURL)
            case .failed:
                if let error = exportSession.error {
                    print("Export failed: \(error.localizedDescription)")
                } else {
                    print("Export failed: Unknown error")
                }
            case .cancelled:
                print("Export cancelled")
            default:
                break
            }
        }
    }

    // Update the progress periodically
    Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
        DispatchQueue.main.async {
            helper.compressionProgress = exportSession.progress
            if exportSession.status != .waiting && exportSession.status != .exporting {
                timer.invalidate()
            }
        }
    }
}

func saveToPhotoLibrary(_ outputURL: URL) {
    PHPhotoLibrary.requestAuthorization { status in
        if status == .authorized {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputURL)
            }) { success, error in
                if success {
                    print("Successfully saved video to photo library.")
                } else {
                    print("Failed to save video: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        } else {
            print("Photo Library access denied.")
        }
    }
}


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
        return FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    }
}
