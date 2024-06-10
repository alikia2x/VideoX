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

// Define a dictionary to map heights to their reference bitrates
let referenceBitrates: [Int: Double] = [
    4320: 48.9,
    2160: 21.4,
    1440: 9.8,
    1080: 5.1,
    720: 2.6,
    480: 1.3,
    360: 0.96
]

// Function to find the nearest height greater than or equal to the given height
func findNearestHeight(_ height: Int) -> Int {
    let heights = referenceBitrates.keys.sorted()
    for h in heights {
        if height <= h {
            return h
        }
    }
    return heights.last! // Return the largest height if no greater height is found
}

// Function to calculate the bitrate based on height and quality
func calculateBitrate(height: Int, quality: Int) -> Int {
    let weight: Double
    switch quality {
    case 1:
        weight = 0.5
    case 2:
        weight = 0.75
    case 3:
        weight = 1.0
    case 4:
        weight = 1.5
    case 5:
        weight = 2.0
    default:
        weight = 1.0
    }

    let nearestHeight = findNearestHeight(height)
    let referenceBitrate = referenceBitrates[nearestHeight] ?? 1.0
    return Int(referenceBitrate * weight * 1_000_000)
}

func getVideoSize(url: URL) async -> CGSize? {
    let asset = AVURLAsset(url: url)
    let videoTrack = try? await asset.loadTracks(withMediaType: .video).first
    
    if (videoTrack == nil) {
        print("Failed to laod tracks")
        return nil
    }
    
    let naturalSize = try? await videoTrack!.load(.naturalSize)
    return naturalSize
}

func getVideoDuration(url: URL) async -> Double? {
    let asset = AVURLAsset(url: url)
    let duration = try? await asset.load(.duration)
    if duration == nil {
        return nil
    }
    return duration!.seconds
}

func getVideoCompressedHeight(naturalSize: CGSize?, resolution: Int) -> Int? {
    if (naturalSize == nil) {
        return nil
    }
    let resolutions: [Int: CGFloat] = [
        0: min(naturalSize!.width, naturalSize!.height), // Original
        2: 2160, // 4K
        3: 1440, // 2K
        4: 1080, // 1080P
        5: 720, // 720P
        7: 480,  // 480P
        8: 360   // 360P
    ]
    guard let targetHeight = resolutions[resolution] else {
        let targetHeight = min(naturalSize!.width, naturalSize!.height)
        return Int(targetHeight)
    }
    return Int(targetHeight)
}

func adjustVideoSettings(videoSettings: inout [String: Any], naturalSize: CGSize, resolution: Int) -> CGFloat {
    let resolutions: [Int: CGFloat] = [
        0: min(naturalSize.width, naturalSize.height), // Original
        2: 2160, // 4K
        3: 1440, // 2K
        4: 1080, // 1080P
        5: 720, // 720P
        7: 480,  // 480P
        8: 360   // 360P
    ]
    
    guard let targetHeight = resolutions[resolution] else {
        let targetHeight = min(naturalSize.width, naturalSize.height)
        if naturalSize.width >= naturalSize.height {
            videoSettings[AVVideoWidthKey] = targetHeight / naturalSize.height * naturalSize.width
            videoSettings[AVVideoHeightKey] = targetHeight
        } else {
            videoSettings[AVVideoWidthKey] = targetHeight
            videoSettings[AVVideoHeightKey] = targetHeight / naturalSize.width * naturalSize.height
        }
        return targetHeight
    }
    
    if naturalSize.width >= naturalSize.height {
        videoSettings[AVVideoWidthKey] = targetHeight / naturalSize.height * naturalSize.width
        videoSettings[AVVideoHeightKey] = targetHeight
    } else {
        videoSettings[AVVideoWidthKey] = targetHeight
        videoSettings[AVVideoHeightKey] = targetHeight / naturalSize.width * naturalSize.height
    }
    return targetHeight
}

func compressVideo(inputURL: URL, helper: Helper, quality: Int, codec: Int, resolution: Int) async {
    let asset = AVAsset(url: inputURL)
    let outputURL = URL.documentsDirectory.appending(path: "compressed.mp4")

    if FileManager.default.fileExists(atPath: outputURL.path) {
        do {
            try FileManager.default.removeItem(at: outputURL)
        } catch {
            print("Error removing existing file: \(error.localizedDescription)")
            return
        }
    }
    
    let videoTrack = try? await asset.loadTracks(withMediaType: .video).first
    
    if (videoTrack == nil) {
        print("Failed to laod tracks")
        return
    }

    // Reader
    guard let reader = try? AVAssetReader(asset: asset) else {
        print("Failed to create AVAssetReader.")
        return
    }
    
    let readerOutput = AVAssetReaderTrackOutput(track: videoTrack!, outputSettings: [
       kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
    ])
    reader.add(readerOutput)
    
    // Writer
    guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4) else {
        print("Failed to create AVAssetWriter.")
        return
    }
    
    
    var videoSettings: [String: Any] = [:]
    
    videoSettings[AVVideoCodecKey] = (codec == 1 ? AVVideoCodecType.h264 : AVVideoCodecType.hevc)
    
    let naturalSize = try? await videoTrack!.load(.naturalSize)
    let transform = try? await videoTrack!.load(.preferredTransform)
    let metadata = try? await videoTrack!.load(.metadata)
    
    if (naturalSize == nil || transform == nil || metadata == nil) { return }
    
    let height = adjustVideoSettings(videoSettings: &videoSettings, naturalSize: naturalSize!, resolution: resolution)
    
    let bitrate: Int = calculateBitrate(height: Int(height), quality: quality)
    
    videoSettings[AVVideoCompressionPropertiesKey] = [
        AVVideoAverageBitRateKey: bitrate
    ]
    
    let writerInput = AVAssetWriterInput(mediaType: .video, outputSettings: videoSettings)
    writerInput.expectsMediaDataInRealTime = false
    writerInput.transform = transform!

    writer.add(writerInput)
    writer.metadata = metadata!
    
    DispatchQueue.main.async {
        helper.isCompressing = true
        helper.compressionProgress = 0.0
    }
    
    writer.startWriting()
    reader.startReading()
    writer.startSession(atSourceTime: .zero)

    let processingQueue = DispatchQueue(label: "videoProcessingQueue")
    
    writerInput.requestMediaDataWhenReady(on: processingQueue) {
       while writerInput.isReadyForMoreMediaData {
           if let buffer = readerOutput.copyNextSampleBuffer() {
               writerInput.append(buffer)
               DispatchQueue.main.async {
                   helper.compressionProgress = Float(CMTimeGetSeconds(CMSampleBufferGetPresentationTimeStamp(buffer)) / CMTimeGetSeconds(asset.duration))
               }
           } else {
               writerInput.markAsFinished()
               writer.finishWriting {
                   reader.cancelReading()
                   DispatchQueue.main.async {
                       DispatchQueue.main.async {
                           helper.isCompressing = false
                       }
                       if writer.status == .completed {
                           helper.previewURL = outputURL
                           saveToPhotoLibrary(outputURL)
                       } else {
                           print("Compression failed: \(writer.error?.localizedDescription ?? "Unknown error")")
                       }
                   }
               }
               break
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
