# MultiCast for macOS 🎧🎧

**MultiCast** is a sleek, native macOS Menu Bar application that allows you to connect and stream audio to multiple Bluetooth headphones or speakers simultaneously.

Normally, macOS only lets you output audio to one device at a time unless you manually dig into the *Audio MIDI Setup* utility and create an Aggregate Device. MultiCast automates this entire process with a beautiful, modern Control Center-style UI right in your menu bar.

## ✨ Features
* **True Multi-Streaming**: Send system audio to 2, 3, or more Bluetooth devices at exactly the same time.
* **Native Apple UI**: Built with SwiftUI using a modern, vibrant popover design that feels right at home on macOS Big Sur and later.
* **Zero Latency Hack**: Uses low-level `CoreAudio` APIs to create a proper "Multi-Output Device" on the fly, mirroring the audio signal exactly as macOS's native tools do.
* **Automatic Cleanup**: Automatically deletes temporary virtual audio devices when you close the app or deselect them.
* **Non-Intrusive**: Runs entirely in your Menu Bar (`LSUIElement`). No dock icons, no clutter.

## 🛠️ How it Works
MultiCast interfaces directly with the macOS **Hardware Abstraction Layer (HAL)** via `CoreAudio`. 
When you select multiple output devices, it programmatically creates an Aggregate Device with the `kAudioAggregateDeviceIsStackedKey` property enabled. This tells macOS to treat the device as a "Multi-Output" device (mirroring audio to all sub-devices) rather than aggregating their channels. It then sets this virtual device as your system's default output.

## 🚀 Installation

### The Easy Way (Recommended)
1. Download the latest `MultiCast.dmg` file from the root of this repository.
2. Double-click the downloaded `.dmg` file to open it.
3. Drag the **MultiCast** app icon into the **Applications** folder shortcut.
4. Open your Applications folder and double-click MultiCast to run it!

### Building from Source
If you prefer to compile it yourself, you can build the native `.app` bundle instantly using the provided shell script:

1. Clone the repository:
   ```bash
   git clone https://github.com/gagantripathi22/MultiCast.git
   cd MultiCast
   ```
2. Run the build script:
   ```bash
   ./build.sh
   ```
3. Install the app:
   ```bash
   cp -R MultiCast.app /Applications/
   ```
4. Open your `Applications` folder and launch **MultiCast**.

## 📖 Usage
1. Make sure your Bluetooth devices are connected to your Mac in your normal Bluetooth settings.
2. Click the AirPods Max icon in your top right Menu Bar.
3. Simply click to toggle the devices you want to stream to.
4. Enjoy synchronized audio across multiple headphones!

## 📜 License
This project is open-sourced under the MIT License. Feel free to fork, modify, and improve it!
