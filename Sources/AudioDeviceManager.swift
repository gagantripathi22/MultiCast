import Foundation
import CoreAudio
import Combine

struct AudioDevice: Identifiable, Hashable {
    let id: AudioDeviceID
    let name: String
    let uid: String
}

class AudioDeviceManager: ObservableObject {
    @Published var availableOutputDevices: [AudioDevice] = []
    @Published var selectedDevices: Set<AudioDevice> = []
    
    private var createdAggregateDeviceID: AudioDeviceID? = nil
    private let aggregateDeviceUID = "com.multicast.aggregate"
    
    init() {
        refreshDevices()
    }
    
    func refreshDevices() {
        availableOutputDevices = getOutputDevices()
        
        // Clean up any stale aggregate devices from a previous crash/run
        cleanupAggregateDevice()
    }
    
    func toggleDeviceSelection(_ device: AudioDevice) {
        if selectedDevices.contains(device) {
            selectedDevices.remove(device)
        } else {
            selectedDevices.insert(device)
        }
        updateAudioRouting()
    }
    
    private func updateAudioRouting() {
        // Remove existing aggregate device if any
        cleanupAggregateDevice()
        
        if selectedDevices.isEmpty {
            return
        }
        
        if selectedDevices.count == 1 {
            // Only one device, just set it as default
            setDefaultOutputDevice(selectedDevices.first!.id)
        } else {
            // Multiple devices, create multi-output
            if let newDeviceID = createMultiOutputDevice(from: Array(selectedDevices)) {
                createdAggregateDeviceID = newDeviceID
                setDefaultOutputDevice(newDeviceID)
            }
        }
    }
    
    private func getOutputDevices() -> [AudioDevice] {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        var status = AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize)
        
        if status != noErr {
            print("Error getting device list size: \(status)")
            return []
        }
        
        let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
        var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
        
        status = AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize, &deviceIDs)
        if status != noErr {
            print("Error getting device IDs: \(status)")
            return []
        }
        
        var outputDevices: [AudioDevice] = []
        
        for id in deviceIDs {
            // Check if device has output channels
            var streamAddress = AudioObjectPropertyAddress(
                mSelector: kAudioDevicePropertyStreams,
                mScope: kAudioDevicePropertyScopeOutput,
                mElement: kAudioObjectPropertyElementMain
            )
            
            var streamDataSize: UInt32 = 0
            status = AudioObjectGetPropertyDataSize(id, &streamAddress, 0, nil, &streamDataSize)
            
            if status == noErr && streamDataSize > 0 {
                // Get name
                var nameAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyDeviceNameCFString,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain
                )
                var nameCF: CFString? = nil
                var nameSize = UInt32(MemoryLayout<CFString?>.size)
                status = AudioObjectGetPropertyData(id, &nameAddress, 0, nil, &nameSize, &nameCF)
                let name = (nameCF as String?) ?? "Unknown Device"
                
                // Get UID
                var uidAddress = AudioObjectPropertyAddress(
                    mSelector: kAudioDevicePropertyDeviceUID,
                    mScope: kAudioObjectPropertyScopeGlobal,
                    mElement: kAudioObjectPropertyElementMain
                )
                var uidCF: CFString? = nil
                var uidSize = UInt32(MemoryLayout<CFString?>.size)
                status = AudioObjectGetPropertyData(id, &uidAddress, 0, nil, &uidSize, &uidCF)
                let uid = (uidCF as String?) ?? ""
                
                // Exclude our own aggregate device from the list
                if uid != aggregateDeviceUID {
                    outputDevices.append(AudioDevice(id: id, name: name, uid: uid))
                }
            }
        }
        
        return outputDevices
    }
    
    private func createMultiOutputDevice(from devices: [AudioDevice]) -> AudioDeviceID? {
        let subDeviceList = devices.map { ["uid": $0.uid] }
        
        let description: [String: Any] = [
            kAudioAggregateDeviceNameKey: "MultiCast Stream",
            kAudioAggregateDeviceUIDKey: aggregateDeviceUID,
            kAudioAggregateDeviceSubDeviceListKey: subDeviceList,
            kAudioAggregateDeviceIsPrivateKey: 0, // 0 to show in MIDI setup, 1 to hide. We'll use 0 so it works reliably across macOS versions
            kAudioAggregateDeviceIsStackedKey: 1  // 1 = Multi-Output (mirrors audio)
        ]
        
        var newDeviceID: AudioDeviceID = 0
        let status = AudioHardwareCreateAggregateDevice(description as CFDictionary, &newDeviceID)
        
        if status == noErr {
            print("Successfully created Multi-Output device with ID \(newDeviceID)")
            return newDeviceID
        } else {
            print("Failed to create aggregate device: \(status)")
            return nil
        }
    }
    
    private func setDefaultOutputDevice(_ deviceID: AudioDeviceID) {
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDefaultOutputDevice,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var idToSet = deviceID
        let status = AudioObjectSetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, UInt32(MemoryLayout<AudioDeviceID>.size), &idToSet)
        
        if status != noErr {
            print("Failed to set default output device: \(status)")
        } else {
            print("Set default output to device ID \(deviceID)")
        }
    }
    
    func cleanupAggregateDevice() {
        if let id = createdAggregateDeviceID {
            let status = AudioHardwareDestroyAggregateDevice(id)
            if status == noErr {
                print("Destroyed aggregate device \(id)")
            }
            createdAggregateDeviceID = nil
            return
        }
        
        // Also try to find by UID in case we crashed previously
        var propertyAddress = AudioObjectPropertyAddress(
            mSelector: kAudioHardwarePropertyDevices,
            mScope: kAudioObjectPropertyScopeGlobal,
            mElement: kAudioObjectPropertyElementMain
        )
        
        var dataSize: UInt32 = 0
        if AudioObjectGetPropertyDataSize(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize) == noErr {
            let deviceCount = Int(dataSize) / MemoryLayout<AudioDeviceID>.size
            var deviceIDs = [AudioDeviceID](repeating: 0, count: deviceCount)
            if AudioObjectGetPropertyData(AudioObjectID(kAudioObjectSystemObject), &propertyAddress, 0, nil, &dataSize, &deviceIDs) == noErr {
                for id in deviceIDs {
                    var uidAddress = AudioObjectPropertyAddress(
                        mSelector: kAudioDevicePropertyDeviceUID,
                        mScope: kAudioObjectPropertyScopeGlobal,
                        mElement: kAudioObjectPropertyElementMain
                    )
                    var uidCF: CFString? = nil
                    var uidSize = UInt32(MemoryLayout<CFString?>.size)
                    if AudioObjectGetPropertyData(id, &uidAddress, 0, nil, &uidSize, &uidCF) == noErr {
                        if (uidCF as String?) == aggregateDeviceUID {
                            AudioHardwareDestroyAggregateDevice(id)
                            print("Cleaned up orphaned aggregate device \(id)")
                        }
                    }
                }
            }
        }
    }
    
    deinit {
        cleanupAggregateDevice()
    }
}
