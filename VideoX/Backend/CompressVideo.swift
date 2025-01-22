//
//  main.swift
//  VideoX
//
//  Created by Alikia2x on 2024/6/10.
//

@preconcurrency import AVFoundation
import AVKit
import Foundation
import Photos
import PhotosUI
import SwiftUI


func compressVideo(
    inputURL: URL, helper: Helper, quality: Int, codec: Int
) async {
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

    // Get video and audio tracks
    let videoTrack = try? await asset.loadTracks(withMediaType: .video).first
    let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first

    if videoTrack == nil || audioTrack == nil {
        print("Failed to load tracks")
        return
    }

    // Reader
    guard let reader = try? AVAssetReader(asset: asset) else {
        print("Failed to create AVAssetReader.")
        return
    }

    // Video reader output
    let videoReaderOutput = AVAssetReaderTrackOutput(
        track: videoTrack!,
        outputSettings: [
            kCVPixelBufferPixelFormatTypeKey as String:
                kCVPixelFormatType_420YpCbCr8BiPlanarFullRange
        ])
    reader.add(videoReaderOutput)

    // Audio reader output
    let audioReaderOutput = AVAssetReaderTrackOutput(
        track: audioTrack!,
        outputSettings: [
            AVFormatIDKey: kAudioFormatLinearPCM
        ])
    reader.add(audioReaderOutput)

    // Writer
    guard let writer = try? AVAssetWriter(outputURL: outputURL, fileType: .mp4)
    else {
        print("Failed to create AVAssetWriter.")
        return
    }

    // Video settings
    var videoSettings: [String: Any] = [:]
    videoSettings[AVVideoCodecKey] =
        (codec == 1 ? AVVideoCodecType.h264 : AVVideoCodecType.hevc)

    // Audio settings
    let audioSettings: [String: Any] = [
        AVFormatIDKey: kAudioFormatMPEG4AAC,
        AVNumberOfChannelsKey: 2,
        AVSampleRateKey: 44100,
        AVEncoderBitRateKey: 128000,
    ]

    let naturalSize = try? await videoTrack!.load(.naturalSize)
    let transform = try? await videoTrack!.load(.preferredTransform)
    let metadata = try? await videoTrack!.load(.metadata)

    if naturalSize == nil || transform == nil || metadata == nil { return }

    let height = adjustVideoSettings(
        videoSettings: &videoSettings, naturalSize: naturalSize!,
        resolution: await helper.targetResolution)

    let bitrate: Int = calculateBitrate(height: Int(height), quality: quality)

    videoSettings[AVVideoCompressionPropertiesKey] = [
        AVVideoAverageBitRateKey: bitrate
    ]

    // Video writer input
    let videoWriterInput = AVAssetWriterInput(
        mediaType: .video, outputSettings: videoSettings)
    videoWriterInput.expectsMediaDataInRealTime = false
    videoWriterInput.transform = transform!
    writer.add(videoWriterInput)

    // Audio writer input
    let audioWriterInput = AVAssetWriterInput(
        mediaType: .audio, outputSettings: audioSettings)
    audioWriterInput.expectsMediaDataInRealTime = false
    writer.add(audioWriterInput)

    writer.metadata = metadata!

    await MainActor.run {
        helper.isCompressing = true
        helper.compressionProgress = 0.0
    }

    writer.startWriting()
    reader.startReading()
    writer.startSession(atSourceTime: .zero)

    let processingQueue = DispatchQueue(label: "videoProcessingQueue")
    let updateInterval = 0.05 // Update progress every 50ms
    var lastUpdateTime = CACurrentMediaTime()

    // Process video and audio
    let group = DispatchGroup()

    // Process video
    group.enter()
    videoWriterInput.requestMediaDataWhenReady(on: processingQueue) {
        while videoWriterInput.isReadyForMoreMediaData {
            if let buffer = videoReaderOutput.copyNextSampleBuffer() {
                videoWriterInput.append(buffer)
                
                let currentTime = CACurrentMediaTime()
                if currentTime - lastUpdateTime >= updateInterval {
                    lastUpdateTime = currentTime
                    let progress = Float(
                        CMTimeGetSeconds(
                            CMSampleBufferGetPresentationTimeStamp(buffer))
                            / CMTimeGetSeconds(asset.duration))
                    
                    Task { @MainActor in
                        helper.compressionProgress = progress
                    }
                }
            } else {
                videoWriterInput.markAsFinished()
                group.leave()
            }
        }
    }

    // Process audio
    group.enter()
    audioWriterInput.requestMediaDataWhenReady(on: processingQueue) {
        while audioWriterInput.isReadyForMoreMediaData {
            if let buffer = audioReaderOutput.copyNextSampleBuffer() {
                audioWriterInput.append(buffer)
            } else {
                audioWriterInput.markAsFinished()
                group.leave()
            }
        }
    }

    // Wait for both video and audio to finish
    group.notify(queue: processingQueue) {
        writer.finishWriting {
            reader.cancelReading()
            Task { @MainActor in
                helper.isCompressing = false
                if writer.status == .completed {
                    helper.previewURL = outputURL
                    saveToPhotoLibrary(outputURL)
                } else {
                    print(
                        "Compression failed: \(writer.error?.localizedDescription ?? "Unknown error")"
                    )
                }
            }
        }
    }
}

func saveToPhotoLibrary(_ outputURL: URL) {
    PHPhotoLibrary.requestAuthorization { status in
        if status == .authorized {
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAssetFromVideo(
                    atFileURL: outputURL)
            }) { success, error in
                if success {
                    print("Successfully saved video to photo library.")
                } else {
                    print(
                        "Failed to save video: \(error?.localizedDescription ?? "Unknown error")"
                    )
                }
            }
        } else {
            print("Photo Library access denied.")
        }
    }
}
