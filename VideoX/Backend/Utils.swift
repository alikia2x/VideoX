
import AVKit
import Foundation
import Photos
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
    360: 0.96,
]

// Function to find the nearest height greater than or equal to the given height
func findNearestHeight(_ height: Int) -> Int {
    let heights = referenceBitrates.keys.sorted()
    for h in heights {
        if height <= h {
            return h
        }
    }
    return heights.last!  // Return the largest height if no greater height is found
}

// Function to calculate the bitrate based on height and quality
func calculateBitrate(height: Int, quality: Int, maxBitrate: Int? = nil) -> Int {
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
    var calculatedBitrate = Int(referenceBitrate * weight * 1_000_000)
    
    // Apply max bitrate limit if provided
    if let maxBitrate = maxBitrate {
        calculatedBitrate = min(calculatedBitrate, maxBitrate)
    }
    
    return calculatedBitrate
}

func getVideoSize(url: URL) async -> CGSize? {
    let asset = AVURLAsset(url: url)
    let videoTrack = try? await asset.loadTracks(withMediaType: .video).first

    if videoTrack == nil {
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

func getTargetShortEdgeLength(naturalSize: CGSize, resolution: Resolution) -> Int {
    let originalShortEdge = min(naturalSize.width, naturalSize.height)
    let originalLongEdge = max(naturalSize.width, naturalSize.height)
    print(originalLongEdge, originalShortEdge, resolution.info.type, resolution.info.value ?? "nil")
    switch resolution.info.type {
    case .long:
        let scale = min(CGFloat(resolution.info.value!) / originalLongEdge, 1.0)
        return Int(originalShortEdge * scale)
    case .short:
        let scale = min(CGFloat(resolution.info.value!) / originalShortEdge, 1.0)
        return Int(originalShortEdge * scale)
    case .original:
        return Int(originalShortEdge)
    }
}

func adjustVideoSettings(
    videoSettings: inout [String: Any], 
    naturalSize: CGSize, 
    resolution: Resolution
) -> CGFloat {
    let originalShortEdge = min(naturalSize.width, naturalSize.height)
    let targetShortEdgeLength = getTargetShortEdgeLength(naturalSize: naturalSize, resolution: resolution)
    let scale = CGFloat(targetShortEdgeLength) / originalShortEdge

    // Adjust the video settings based on the calculated scale
    videoSettings[AVVideoWidthKey] = naturalSize.width * scale
    videoSettings[AVVideoHeightKey] = naturalSize.height * scale
    return CGFloat(targetShortEdgeLength)
}
