import SwiftUI
import PhotosUI

struct CompressionControlsView: View {
    @ObservedObject var helper: Helper
    @Binding var selectedItem: PhotosPickerItem?
    @Binding var loadState: LoadState
    @Binding var selectedQuality: Int
    @Binding var selectedCodec: Int
    
    var body: some View {
        VStack(alignment: .leading) {
            Label("Compress!", systemImage: "3.circle")
                .font(.title2)
                .bold()
            
            if helper.isCompressing {
                Text(NSLocalizedString("Compress Progress: ", comment: "") + String(Int(helper.compressionProgress * 100)) + "%")
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
                        await compressVideo(
                            inputURL: helper.selectedMovive!.url,
                            helper: helper,
                            quality: selectedQuality,
                            codec: selectedCodec
                        )
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
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
        .padding(.leading, 16)
        .padding(.top, 16)
    }
}
