import SwiftUI
import PhotosUI

struct VideoPickerView: View {
    @Binding var selectedItem: PhotosPickerItem?
    @ObservedObject var helper: Helper
    @Binding var loadState: LoadState
    
    var body: some View {
        VStack(alignment: .leading) {
            Label("Select video", systemImage: "1.circle")
                .font(.title2)
                .bold()
            
            PhotosPicker("Pick video", selection: $selectedItem, matching: .videos, preferredItemEncoding: .current)
                .onChange(of: selectedItem) { newItem in
                    if selectedItem == nil { return }
                    
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
                                if helper.videoSize != nil {
                                    let resolution = helper.targetResolution
                                    let compressedHeight = getTargetShortEdgeLength(naturalSize: helper.videoSize!, resolution: resolution)
                                    helper.calculatedBitrate = calculateBitrate(height: compressedHeight, quality: 3)
                                }
                                else {
                                    loadState = .failed
                                }
                            } else {
                                loadState = .failed
                            }
                        } catch {
                            loadState = .failed
                        }
                    }
                }
                .font(.title3)
                .fontWeight(.bold)
                .padding(.top, 1)
                .padding(.leading, 36)
                .disabled(helper.isCompressing)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
        .padding(.leading, 16)
        .padding(.top, 16)
    }
}
