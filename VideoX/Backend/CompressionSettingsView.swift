import SwiftUI

struct CompressionSettingsView: View {
    @ObservedObject var helper: Helper
    @Binding var selectedQuality: Int
    @Binding var selectedCodec: Int
    @State private var selectedResolution: Resolution = .resolutionOriginal
    let presets: [Resolution] = [
        .resolutionOriginal,
        .resolution4K, .resolution2K, .resolution1080P, .resolution720P,
        .resolution540P, .resolution480P, .resolution360P,
    ]
    let presetsName: [String] = [
        "Original", "4K", "2K", "1080P", "720P", "540P", "480P", "360P",
    ]

    var body: some View {
        VStack(alignment: .leading) {
            Label("Select options", systemImage: "2.circle")
                .font(.title2)
                .bold()

            List {
                Picker("Quality", selection: $selectedQuality) {
                    Text("Highest").tag(5)
                    Text("High").tag(4)
                    Text("Medium").tag(3)
                    Text("Low").tag(2)
                    Text("Lowest").tag(1)
                }
                .onChange(of: selectedQuality) { _ in
                    if helper.videoSize == nil {
                        return
                    }
                    let compressedHeight = getTargetShortEdgeLength(
                        naturalSize: helper.videoSize!,
                        resolution: helper.targetResolution)
                    helper.calculatedBitrate = calculateBitrate(
                        height: compressedHeight, quality: selectedQuality)
                }

                Picker("Codec", selection: $selectedCodec) {
                    Text("H.264").tag(1)
                    Text("HEVC").tag(2)
                }

                Picker("Resolution", selection: $selectedResolution) {
                    ForEach(0..<8) { index in
                        Text(NSLocalizedString(presetsName[index], comment: "")).tag(presets[index])
                    }
                }
                .onChange(of: selectedResolution) { newResolution in
                    helper.targetResolution = newResolution
                    let compressedHeight = getTargetShortEdgeLength(
                        naturalSize: helper.videoSize!,
                        resolution: helper.targetResolution)
                    helper.calculatedBitrate = calculateBitrate(
                        height: compressedHeight, quality: selectedQuality)
                }

                if helper.videoLength != nil && helper.calculatedBitrate != nil
                {
                    let count = Measurement(
                        value: Double(helper.calculatedBitrate!) * helper
                            .videoLength!, unit: UnitInformationStorage.bits)
                    let formatted = count.formatted(.byteCount(style: .memory))
                    Text(
                        String(
                            round(Float(helper.calculatedBitrate!) / 10000.00)
                                / 100) + "Mbps" + ", Est size: " + formatted)
                } else if helper.calculatedBitrate != nil {
                    Text(
                        String(
                            round(Float(helper.calculatedBitrate!) / 10000.00)
                                / 100) + "Mbps")
                }
            }
            .listStyle(.plain)
            .padding(.leading, 16)
            .frame(maxHeight: 152)
        }
        .frame(minWidth: 0, maxWidth: .infinity, alignment: .topLeading)
        .padding(.leading, 16)
        .padding(.top, 16)
    }
}
