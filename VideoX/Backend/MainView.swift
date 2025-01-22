//
//  MainView.swift
//  VideoX
//
//  Created by Alikia2x on 2024/6/10.
//

import SwiftUI
import AVKit
import PhotosUI
import AVFoundation

struct PlayerViewController: UIViewControllerRepresentable {
    var videoURL: URL?

    private var player: AVPlayer {
        return AVPlayer(url: videoURL!)
    }

    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.modalPresentationStyle = .fullScreen
        controller.player = player
        controller.player?.play()
        return controller
    }

    func updateUIViewController(_ playerController: AVPlayerViewController, context: Context) {}
}

enum LoadState {
    case unknown, loading, loaded, failed
}

struct MainView: View {
    @ObservedObject var helper = Helper()
    @State private var selectedItem: PhotosPickerItem?
    @State private var loadState = LoadState.unknown
    @State private var selectedQuality: Int = 2
    @State private var selectedCodec: Int = 1
    @State private var selectedResolution: Int = 0
    
    var body: some View {
        NavigationStack {
            VStack(alignment: .leading) {
                VideoPickerView(
                    selectedItem: $selectedItem,
                    helper: helper,
                    loadState: $loadState
                )
                
                VideoPreviewView(
                    helper: helper,
                    loadState: $loadState
                )
                
                CompressionSettingsView(
                    helper: helper,
                    selectedQuality: $selectedQuality,
                    selectedCodec: $selectedCodec
                )
                
                CompressionControlsView(
                    helper: helper,
                    selectedItem: $selectedItem,
                    loadState: $loadState,
                    selectedQuality: $selectedQuality,
                    selectedCodec: $selectedCodec
                )
                
                ResultPreviewView(helper: helper)
                
                Spacer()
            }
            .navigationTitle("VideoX")
        }
    }
}

#Preview {
    MainView()
}
