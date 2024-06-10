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
    @State private var compressionProgress: Float = 0.0
    @State private var isCompressing = false
    @State private var selectedQuality: Int = 2
    @State private var selectedCodec: Int = 1
    @State private var selectedResolution: Int = 0
    
    var body: some View {
        NavigationStack {
            VStack (alignment: .leading) {
                VStack (alignment: .leading){
                    Label("Select video", systemImage: "1.circle")
                        .font(.title2)
                        .bold()
                    PhotosPicker("Pick video", selection: $selectedItem, matching: .videos)
                        .onChange(of: selectedItem, {
                            if (selectedItem == nil) {
                                return
                            }
                            helper.selectedMovive = nil
                            helper.previewURL = nil
                            helper.isCompressing = false
                            helper.compressionProgress = 0.0
                            loadState = .loading
                            Task {
                                do {
                                    if let movie = try await selectedItem?.loadTransferable(type: Movie.self) {
                                        loadState = .loaded
                                        helper.selectedMovive = movie
                                        helper.videoSize = await getVideoSize(url: movie.url)
                                        helper.videoLength = await getVideoDuration(url: movie.url)
                                        let compressedHeight = getVideoCompressedHeight(naturalSize: helper.videoSize, resolution: selectedResolution)
                                        if (compressedHeight != nil ){
                                            helper.calculatedBitrate = calculateBitrate(height: compressedHeight!, quality: selectedQuality)
                                        }
                                        print("Loaded")
                                    }
                                    else {
                                        loadState = .failed
                                        print("Failed")
                                    }
                                } catch {
                                    loadState = .failed
                                    print("Failed")
                                }
                            }
                        })
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.top, 1)
                        .padding(.leading, 36)
                        .disabled(helper.isCompressing)
                }
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    alignment: .topLeading
                )
                .padding(.leading, 16)
                .padding(.top, 16)
                
                VStack (alignment: .leading){
                    switch loadState {
                        case .unknown:
                            EmptyView()
                        case .loading:
                            Label("Loading Video", systemImage: "info.circle")
                                .font(.title2)
                                .bold()
                            ProgressView()
                                .padding(.leading, 36)
                        case .loaded:
                            if (helper.selectedMovive != nil) {
                                Label("Selected Video", systemImage: "info.circle")
                                    .font(.title2)
                                    .bold()
                                PlayerViewController(videoURL: helper.selectedMovive!.url)
                                    .frame(width: UIScreen.main.bounds.width - 64, height: 192)
                                    .padding(.leading, 36)
                            }
                        case .failed:
                            Label("Status", systemImage: "exclamationmark.circle")
                                .font(.title2)
                                .bold()
                            Text("Import failed")
                                .padding(.leading, 36)
                                .foregroundStyle(.red)
                    }
                }
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    alignment: .topLeading
                )
                .padding(.leading, 16)
                .padding(.top, 16)
                
                
                VStack (alignment: .leading){
                    Label("Select options", systemImage: "2.circle")
                        .font(.title2)
                        .bold()
                    List{
                        Picker("Quality", selection: $selectedQuality, content: {
                            Text("Highest").tag(5)
                            Text("High").tag(4)
                            Text("Medium").tag(3)
                            Text("Low").tag(2)
                            Text("Lowest").tag(1)
                        })
                        .onChange(of: selectedQuality, {
                            let compressedHeight = getVideoCompressedHeight(naturalSize: helper.videoSize, resolution: selectedResolution)
                            if (compressedHeight == nil ){
                                return
                            }
                            helper.calculatedBitrate = calculateBitrate(height: compressedHeight!, quality: selectedQuality)
                        })
                        Picker("Codec", selection: $selectedCodec, content: {
                            Text("H.264").tag(1)
                            Text("HEVC").tag(2)
                        })
                        Picker("Resolution", selection: $selectedResolution, content: {
                            Text("Original").tag(0)
                            // 1 reserved for 8K
                            Text("4K").tag(2)
                            Text("2K").tag(3)
                            Text("1080P").tag(4)
                            Text("720P").tag(5)
                            // 6 reserved for 540P
                            Text("480P").tag(7)
                            Text("360P").tag(8)
                        })
                        .onChange(of: selectedResolution, {
                            let compressedHeight = getVideoCompressedHeight(naturalSize: helper.videoSize, resolution: selectedResolution)
                            if (compressedHeight == nil ){
                                return
                            }
                            helper.calculatedBitrate = calculateBitrate(height: compressedHeight!, quality: selectedQuality)
                        })
                        if (helper.videoLength != nil && helper.calculatedBitrate != nil) {
                            let count = Measurement(value: Double(helper.calculatedBitrate!) * helper.videoLength!, unit: UnitInformationStorage.bits)
                            let formatted = count.formatted(.byteCount(style: .memory))
                            Text(String(round(Float(helper.calculatedBitrate!) / 10000.00)/100) + "Mbps" + ", Est size: " + formatted)
                        } else if (helper.calculatedBitrate != nil) {
                            Text(String(round(Float(helper.calculatedBitrate!) / 10000.00)/100) + "Mbps")
                        }
                    }
                    .listStyle(.plain)
                    .padding(.leading, 16)
                    .frame(maxHeight: 152)
                }
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    alignment: .topLeading
                )
                .padding(.leading, 16)
                .padding(.top, 16)
                
                VStack (alignment: .leading){
                    Label("Compress!", systemImage: "3.circle")
                        .font(.title2)
                        .bold()
                    if (helper.isCompressing) {
                        Text("Compress Progress: " + String(Int(helper.compressionProgress * 100)) + "%")
                            .padding(.leading, 36)
                            .padding(.top, 1)
                        ProgressView(value: helper.compressionProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .padding(.top, 12)
                            .padding(.leading, 36)
                            .padding(.trailing, 36)
                            .transition(.opacity)
                    } else {
                        Button(action: {
                            Task {
                                await compressVideo(inputURL: helper.selectedMovive!.url, helper: helper, quality: selectedQuality, codec: selectedCodec, resolution: selectedResolution)
                                helper.selectedMovive = nil
                                selectedItem = nil
                                loadState = .unknown
                            }
                        }) {
                            Text("Compress and Save Video")
                                .font(.headline)
                                .fontWeight(.medium)
                                .padding(.leading, 36)
                                .padding(.top, 1)
                        }
                        .disabled(helper.selectedMovive == nil)
                    }
                }
                .frame(
                    minWidth: 0,
                    maxWidth: .infinity,
                    alignment: .topLeading
                )
                .padding(.leading, 16)
                .padding(.top, 16)
                
                if (helper.isCompressing == false) {
                    VStack (alignment: .leading){
                        if (helper.previewURL != nil){
                            Label("Compressed Result", systemImage: "checkmark.circle")
                                .font(.title2)
                                .bold()
                            PlayerViewController(videoURL: helper.previewURL)
                                .frame(width: UIScreen.main.bounds.width - 64, height: 192)
                                .padding(.leading, 36)
                        }
                    }
                    .frame(
                        minWidth: 0,
                        maxWidth: .infinity,
                        alignment: .topLeading
                    )
                    .padding(.leading, 16)
                    .padding(.top, 16)
                    .transition(.opacity)
                }
                
                Spacer()
            }
            .navigationTitle("VideoX")
        }
    }
}

#Preview {
    MainView()
}
