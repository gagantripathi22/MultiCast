import SwiftUI

@main
struct MultiCastApp: App {
    @StateObject private var audioManager = AudioDeviceManager()
    
    var body: some Scene {
        MenuBarExtra("MultiCast", systemImage: "airpodsmax") {
            ContentView(audioManager: audioManager)
        }
        .menuBarExtraStyle(.window) // Using window prevents the menu from closing on every click
    }
}

struct ContentView: View {
    @ObservedObject var audioManager: AudioDeviceManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("MultiCast Output")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(action: {
                    audioManager.refreshDevices()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    audioManager.cleanupAggregateDevice()
                    NSApplication.shared.terminate(nil)
                }) {
                    Image(systemName: "power")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
                .padding(.leading, 8)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            Divider()
            
            // Device List
            ScrollView {
                VStack(spacing: 6) {
                    if audioManager.availableOutputDevices.isEmpty {
                        Text("No output devices found.")
                            .foregroundColor(.secondary)
                            .padding(.top, 20)
                    } else {
                        ForEach(audioManager.availableOutputDevices) { device in
                            DeviceRow(
                                device: device,
                                isSelected: audioManager.selectedDevices.contains(device)
                            ) {
                                audioManager.toggleDeviceSelection(device)
                            }
                        }
                    }
                }
                .padding(12)
            }
            .frame(height: min(CGFloat(audioManager.availableOutputDevices.count * 44 + 24), 300))
            
            // Footer status
            if audioManager.selectedDevices.count > 1 {
                Divider()
                HStack {
                    Image(systemName: "speaker.wave.3.fill")
                        .foregroundColor(.accentColor)
                    Text("Streaming to \(audioManager.selectedDevices.count) devices")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(NSColor.controlBackgroundColor).opacity(0.5))
            }
        }
        .frame(width: 320)
        // Background matching modern macOS popovers
        .background(VisualEffectView(material: .popover, blendingMode: .behindWindow))
    }
}

struct DeviceRow: View {
    let device: AudioDevice
    let isSelected: Bool
    let action: () -> Void
    
    @State private var isHovering = false
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Determine icon based on name (simple heuristic)
                let iconName = getIconName(for: device.name)
                
                Image(systemName: iconName)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .white : .accentColor)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(isSelected ? Color.accentColor : Color.accentColor.opacity(0.1))
                    )
                
                Text(device.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                }
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isSelected ? Color.accentColor : (isHovering ? Color(NSColor.controlBackgroundColor) : Color.clear))
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
        .onHover { hovering in
            self.isHovering = hovering
        }
    }
    
    private func getIconName(for name: String) -> String {
        let lowercased = name.lowercased()
        if lowercased.contains("airpods") {
            return "airpodsmax" // Could differentiate pro/max/normal but this is a fallback
        } else if lowercased.contains("headphone") {
            return "headphones"
        } else if lowercased.contains("speaker") {
            return "speaker.wave.2.fill"
        } else if lowercased.contains("macbook") {
            return "laptopcomputer"
        } else {
            return "speaker.wave.2.fill"
        }
    }
}

// Helper to get true macOS vibrancy
struct VisualEffectView: NSViewRepresentable {
    let material: NSVisualEffectView.Material
    let blendingMode: NSVisualEffectView.BlendingMode
    
    func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }
    
    func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}
