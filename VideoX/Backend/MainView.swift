//
//  MainView.swift
//  VideoX
//
//  Created by Alikia2x on 2024/6/10.
//

import SwiftUI
import AVKit
import PhotosUI

enum LoadState {
    case unknown, loading, loaded, failed
}

struct MainView: View {
    @ObservedObject var helper = Helper()
    @State private var selectedItem: PhotosPickerItem?
    @State private var loadState = LoadState.unknown
    @State private var compressionProgress: Float = 0.0
    @State private var isCompressing = false
    
    var body: some View {
        NavigationStack {
            VStack (alignment: .leading) {
                VStack (alignment: .leading){
                    Label("Select video", systemImage: "1.circle")
                        .font(.title2)
                        .bold()
                    PhotosPicker("Pick video", selection: $selectedItem, matching: .videos)
                        .onChange(of: selectedItem, {
                            helper.selectedMovive = nil
                            Task {
                                do {
                                    loadState = .loading
                                    if let movie = try await selectedItem?.loadTransferable(type: Movie.self) {
                                        loadState = .loaded
                                        helper.selectedMovive = movie
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
                    Text("Nothing here yet... (#ﾟДﾟ)")
                        .padding(.leading, 36)
                        .padding(.top, 1)
                        .font(.headline)
                        .fontWeight(.medium)
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
                    Button(action: {
                        compressVideo(inputURL: helper.selectedMovive!.url, helper: helper)
                    }) {
                        Text("Compress and Save Video")
                            .font(.headline)
                            .fontWeight(.medium)
                            .padding(.leading, 36)
                            .padding(.top, 1)
                    }
                    .disabled(helper.isCompressing)
                    .disabled(helper.selectedMovive == nil)
                    if (helper.isCompressing) {
                        ProgressView(value: helper.compressionProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .padding(.top, 12)
                            .padding(.leading, 36)
                            .padding(.trailing, 36)
                            .transition(.opacity)
                    }
                }
                .frame(
                  minWidth: 0,
                  maxWidth: .infinity,
                  alignment: .topLeading
                )
                .padding(.leading, 16)
                .padding(.top, 16)
                
                if (loadState == .loaded && helper.selectedMovive != nil && helper.isCompressing == false) {
                    VStack (alignment: .leading){
                        
                        switch loadState {
                            case .unknown:
                                EmptyView()
                            case .loading:
                                Label("Selected Video", systemImage: "info.circle")
                                    .font(.title2)
                                    .bold()
                                ProgressView()
                                    .padding(.leading, 36)
                            case .loaded:
                                if (helper.previewURL == nil) {
                                    Label("Selected Video", systemImage: "info.circle")
                                        .font(.title2)
                                        .bold()
                                    VideoPlayer(player: AVPlayer(url: helper.selectedMovive!.url))
                        
                                }
                            case .failed:
                                Label("Status", systemImage: "exclamationmark.circle")
                                    .font(.title2)
                                    .bold()
                                Text("Import failed")
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
