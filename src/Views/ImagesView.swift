import SwiftUI

struct ImagesView: View {
    @ObservedObject var store: AuraRuntimeStore
    @State private var searchText = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 10) {
                AuraSectionHeader("Images", subtitle: "\(filteredImages.count) local images", systemImage: "square.stack.3d.up")
                Spacer()
                Button {
                    store.appendLog("Image pull is not implemented yet; use the CLI command path for now.", level: .warning)
                } label: {
                    Label("Pull", systemImage: "arrow.down.circle")
                }
                .buttonStyle(AuraCompactButtonStyle(prominent: true))

                Button {
                    store.appendLog("Image removal is not implemented yet; use the CLI command path for now.", level: .warning)
                } label: {
                    Label("Remove", systemImage: "trash")
                }
                .buttonStyle(AuraCompactButtonStyle())
            }

            if filteredImages.isEmpty {
                AuraEmptyState(
                    title: searchText.isEmpty ? "No images found" : "No images match this search",
                    message: searchText.isEmpty ? "Pull or build an image to make it available to local containers." : "Try a different repository, tag, size, or image ID.",
                    systemImage: "square.stack.3d.up"
                )
            } else {
                AuraSurface {
                    VStack(spacing: 0) {
                        header
                        Divider()
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(filteredImages) { image in
                                    row(image)
                                    if image.id != filteredImages.last?.id {
                                        Divider()
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .auraPage()
        .searchable(text: $searchText, prompt: "Search images")
    }

    private var header: some View {
        HStack(spacing: 14) {
            tableLabel("Repository")
            tableLabel("Tag", width: 120)
            tableLabel("Size", width: 100)
            tableLabel("Created", width: 140)
            tableLabel("Image ID", width: 130)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.secondary.opacity(0.06))
    }

    private func row(_ image: AuraImage) -> some View {
        HStack(spacing: 14) {
            HStack(spacing: 9) {
                Image(systemName: "square.stack.3d.up")
                    .foregroundStyle(AuraTheme.accent)
                    .frame(width: 22)
                Text(image.name)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Text(image.tag)
                .font(.caption.monospaced())
                .frame(width: 120, alignment: .leading)

            Text(image.size)
                .font(.caption.monospacedDigit())
                .foregroundStyle(.secondary)
                .frame(width: 100, alignment: .leading)

            Text(relativeDate(image.createdAt))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 140, alignment: .leading)

            Text(shortID(image.id))
                .font(.caption2.monospaced())
                .foregroundStyle(.secondary)
                .frame(width: 130, alignment: .leading)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
    }

    private var filteredImages: [AuraImage] {
        store.filteredImages(searchText)
    }

    private func tableLabel(_ value: String, width: CGFloat? = nil) -> some View {
        Text(value.uppercased())
            .font(.caption2.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(width: width, alignment: .leading)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func shortID(_ id: String) -> String {
        String(id.prefix(12))
    }
}
