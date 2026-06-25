import SwiftUI

struct ConverterView: View {
    @ObservedObject var store: AuraPlaceholderStore
    @State private var dockerInput = ""
    @State private var convertedCommand = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Docker to Apple Container")
                .font(.title3)
                .bold()
            Text("Paste a Docker Compose or `docker run` snippet to generate an equivalent command.")
                .font(.caption)
                .foregroundStyle(.secondary)

            TextEditor(text: $dockerInput)
                .font(.system(.body, design: .monospaced))
                .frame(minHeight: 180)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.25)))
                .padding(.bottom, 6)

            HStack {
                Button("Convert") {
                    convertCommand()
                }
                .buttonStyle(.borderedProminent)

                Button("Clear") {
                    dockerInput = ""
                    convertedCommand = ""
                }
                .buttonStyle(.bordered)
            }

            if !convertedCommand.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Generated command")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(convertedCommand)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            Spacer()
        }
        .padding(14)
        .navigationTitle("Converter")
    }

    private func convertCommand() {
        let mockImage = "nginx:latest"
        let mockPorts = ["8080:80"]
        let mockName = "web-service"
        let args = ConversionService.convert(config: DockerConfig(image: mockImage, ports: mockPorts, name: mockName))
        convertedCommand = "container " + args.joined(separator: " ")
        store.appendLog("Converted docker input to Apple Container command.")
    }
}
