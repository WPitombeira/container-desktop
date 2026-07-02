import SwiftUI

struct ConverterView: View {
    @ObservedObject var store: AuraRuntimeStore
    @State private var dockerInput = ""
    @State private var convertedCommand = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            AuraSectionHeader(
                "Docker command converter",
                subtitle: "Paste a Docker command and generate an Apple Container equivalent.",
                systemImage: "arrow.left.arrow.right"
            )

            AuraSurface {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Input")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    TextEditor(text: $dockerInput)
                        .font(.system(.body, design: .monospaced))
                        .frame(minHeight: 180)
                        .scrollContentBackground(.hidden)
                        .padding(8)
                        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

                    HStack {
                        Button {
                            convertCommand()
                        } label: {
                            Label("Convert", systemImage: "wand.and.stars")
                        }
                        .buttonStyle(AuraCompactButtonStyle(prominent: true))

                        Button {
                            dockerInput = ""
                            convertedCommand = ""
                        } label: {
                            Label("Clear", systemImage: "xmark")
                        }
                        .buttonStyle(AuraCompactButtonStyle())

                        Spacer()
                    }
                }
                .padding(16)
            }

            if !convertedCommand.isEmpty {
                AuraSurface {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Generated command")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                        Text(convertedCommand)
                            .font(.system(.body, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.secondary.opacity(0.07), in: RoundedRectangle(cornerRadius: 6, style: .continuous))
                    }
                    .padding(16)
                }
            }

            Spacer()
        }
        .auraPage()
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
