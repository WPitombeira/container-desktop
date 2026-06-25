import SwiftUI

struct ImagesView: View {
    @ObservedObject var store: AuraPlaceholderStore
    @State private var searchText = ""

    var body: some View {
        List(filteredImages) { image in
            HStack {
                Image(systemName: "photo")
                    .foregroundStyle(.secondary)
                    .frame(width: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text("\(image.name):\(image.tag)").bold()
                    Text("Size \(image.size) • Created \(relativeDate(image.createdAt))").font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.vertical, 2)
        }
        .searchable(text: $searchText, prompt: "Search images")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("Pull") {
                    store.appendLog("Image pull action is waiting for service wiring.")
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Remove") {
                    store.appendLog("Image removal is waiting for service wiring.")
                }
            }
        }
        .navigationTitle("Images")
    }

    private var filteredImages: [AuraImage] {
        store.filteredImages(searchText)
    }

    private func relativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}
