import SwiftUI

struct AuraView: View {
    @StateObject private var engine = AuraEngine()
    @State private var selectedTab: String = "Dashboard"
    @State private var dockerInput: String = ""
    @State private var convertedCommand: String = ""
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedTab) {
                NavigationLink(value: "Dashboard") {
                    Label("Dashboard", systemImage: "square.grid.2x2")
                }
                NavigationLink(value: "Converter") {
                    Label("Docker Converter", systemImage: "arrow.up.right.circle")
                }
                NavigationLink(value: "Settings") {
                    Label("Settings", systemImage: "gearshape")
                }
            }
            .listStyle(.sidebar)
            .navigationTitle("Aura")
        } detail: {
            switch selectedTab {
            case "Dashboard":
                DashboardView(engine: engine)
            case "Converter":
                ConverterView(engine: engine, dockerInput: $dockerInput, convertedCommand: $convertedCommand)
            case "Settings":
                Text("Settings & Configuration")
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            default:
                Text("Select an option")
            }
        }
    }
}

struct DashboardView: View {
    @ObservedObject var engine: AuraEngine
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Container Status")
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                Spacer()
                Circle()
                    .fill(engine.isRunning ? Color.green : Color.gray)
                    .frame(width: 12, height: 12)
                Text(engine.isRunning ? "Running" : "Idle")
                    .font(.caption)
            }
            .padding()

            // Log Console
            VStack(alignment: .leading) {
                Text("Live Logs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                ScrollView {
                    Text(engine.containerLogs)
                        .font(.system(.caption, design: .monospaced))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(8)
                        .background(Color.black.opacity(0.05))
                        .cornerRadius(8)
                }
                .frame(height: 300)
            }
            .padding(.horizontal)

            // Controls
            HStack {
                Button(action: {
                    engine.runContainerCommand(["--help"])
                }) {
                    Label("Test Connection", systemImage: "bolt.fill")
                }
                .buttonStyle(.borderedProminent)
                
                Button(action: {
                    engine.containerLogs = ""
                }) {
                    Label("Clear Logs", systemImage: "trash")
                }
                .buttonStyle(.bordered)
            }
            
            if let error = engine.error {
                Text(error)
                    .foregroundColor(.red)
                    .font(.caption)
                    .padding()
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Dashboard")
    }
}

struct ConverterView: View {
    @ObservedObject var engine: AuraEngine
    @Binding var dockerInput: String
    @Binding var convertedCommand: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Docker to Apple Container")
                .font(.system(size: 24, weight: .bold, design: .rounded))
            
            Text("Paste your Docker Compose service or Docker run command below to convert it to Apple Container syntax.")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            TextEditor(text: $dockerInput)
                .font(.system(.body, design: .monospaced))
                .frame(height: 200)
                .padding(4)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2)))
            
            Button(action: performConversion) {
                HStack {
                    Image(systemName: "wand.and.stars")
                    Text("Convert Now")
                }
                .frame(maxWidth: .infinity)
                .padding()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            
            if !convertedCommand.isEmpty {
                VStack(alignment: .leading) {
                    Text("Resulting Command:")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(convertedCommand)
                        .font(.system(.body, design: .monospaced))
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            
            Spacer()
        }
        .padding()
        .navigationTitle("Converter")
    }
    
    func performConversion() {
        // For the MVP, we simulate the parsing of the input
        // In the real app, this will use a YAML parser on the dockerInput string
        let mockImage = "nginx:latest"
        let mockPorts = ["8080:80"]
        let mockName = "web-service"
        
        let args = engine.convertDockerCompose(image: mockImage, ports: mockPorts, name: mockName)
        convertedCommand = "container " + args.joined(separator: " ")
    }
}
