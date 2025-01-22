import SwiftUI
import AVKit

struct ResultPreviewView: View {
    @ObservedObject var helper: Helper
    
    var body: some View {
        if helper.isCompressing == false && helper.previewURL != nil {
            VStack(alignment: .leading) {
                Label("Compressed Result", systemImage: "checkmark.circle")
                    .font(.title2)
                    .bold()
                PlayerViewController(videoURL: helper.previewURL)
                    .frame(width: UIScreen.main.bounds.width - 64, height: 192)
                    .padding(.leading, 36)
            }
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
            .padding(.leading, 16)
            .padding(.top, 16)
            .transition(.opacity)
        }
    }
}
