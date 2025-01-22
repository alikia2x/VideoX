import SwiftUI
import AVKit

struct VideoPreviewView: View {
    @ObservedObject var helper: Helper
    @Binding var loadState: LoadState
    
    var body: some View {
        VStack(alignment: .leading) {
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
                if helper.selectedMovive != nil {
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
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
        .padding(.leading, 16)
        .padding(.top, 16)
    }
}
