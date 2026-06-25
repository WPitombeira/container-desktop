import SwiftUI

struct ConverterView: View {
    @ObservedObject var store: AuraRuntimeStore
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
        let trimmedInput = dockerInput.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedInput.isEmpty else {
            convertedCommand = "Conversion failed: paste a docker command before converting."
                .capitalized
            store.appendLog("Conversion skipped: input was empty.", level: .warning)
            return
        }

        let result = ConversionService.convert(command: trimmedInput)

        if !result.warnings.isEmpty {
            result.warnings.forEach { store.appendLog("Converter warning: \($0)", level: .warning) }
        }

        if result.command.isEmpty {
            let warningText = result.warnings.joined(separator: "\n")
            convertedCommand = warningText.isEmpty
                ? "Conversion failed."
                : "Conversion failed.\n\(warningText)"
            store.appendLog("Conversion failed for provided docker command.", level: .error)
            return
        }

        convertedCommand = "container " + result.command.joined(separator: " ")
        if !result.warnings.isEmpty {
            convertedCommand += "\nWarnings:\n" + result.warnings.map { "• \($0)" }.joined(separator: "\n")
        }
        store.appendLog("Converted docker input to Apple Container command.")
    }
}
