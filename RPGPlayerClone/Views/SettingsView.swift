import SwiftUI
import WebKit

struct SettingsView: View {
    @AppStorage("settings.virtualGamepadEnabled") private var virtualGamepadEnabled = true
    @AppStorage("settings.virtualGamepadOpacity") private var virtualGamepadOpacity = 0.78
    @AppStorage("settings.virtualGamepadLayout") private var virtualGamepadLayout = "standard"
    @AppStorage("settings.inputSensitivity") private var inputSensitivity = 0.55

    @State private var cacheStatus: String?

    var body: some View {
        Form {
            Section("Virtual gamepad") {
                Toggle("Bat phim ao", isOn: $virtualGamepadEnabled)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Do trong")
                    Slider(value: $virtualGamepadOpacity, in: 0.2...1.0)
                    Text(String(format: "%.2f", virtualGamepadOpacity))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Do nhay input")
                    Slider(value: $inputSensitivity, in: 0.1...1.0)
                    Text(String(format: "%.2f", inputSensitivity))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Picker("Bo cuc", selection: $virtualGamepadLayout) {
                    Text("Standard").tag("standard")
                    Text("Compact").tag("compact")
                }
            }

            Section("Cache") {
                Button("Xoa cache web va file tam", role: .destructive) {
                    clearCache()
                }

                if let cacheStatus {
                    Text(cacheStatus)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func clearCache() {
        Task {
            let dataTypes = WKWebsiteDataStore.allWebsiteDataTypes()
            let startDate = Date(timeIntervalSince1970: 0)

            await withCheckedContinuation { continuation in
                WKWebsiteDataStore.default().removeData(ofTypes: dataTypes, modifiedSince: startDate) {
                    continuation.resume()
                }
            }

            let cacheRoot = FileManager.cachesDirectory.appendingPathComponent("RPGPlayerClone", isDirectory: true)
            try? FileManager.default.removeItem(at: cacheRoot)
            cacheStatus = "Da xoa cache web va file tam."
        }
    }
}

