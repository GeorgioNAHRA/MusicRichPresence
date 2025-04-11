# Music Rich Presence

<p align="center">
  <img src="assets/icon.png" alt="App Icon" width="120" />
</p>

> 🎵 A native macOS SwiftUI app to display your currently playing Apple Music track in your Discord Rich Presence — live, beautiful, and automatic.

---

<p align="center">
  Developed with ❤️ by <a href="https://github.com/georgionahra">Georgio Nahra</a>
</p>

---

## 📚 Table of Contents

- [✨ Features](#-features)
- [📸 Preview](#-preview)
- [🧱 Tech Stack](#-tech-stack)
- [🚀 Installation](#-installation)
- [🛠️ Requirements](#-requirements)
- [🧩 Permissions](#-permissions)
- [⚠️ Troubleshooting](#-troubleshooting)
- [📄 License](#-license)
- [👑 Credits](#-credits)

---

## ✨ Features

- 🎧 Displays the **current song**, **album**, and **artist** from Apple Music  
- 🕒 Shows real-time **progress timer** (start → end) when playing  
- 🖼️ Automatically fetches and displays **album artwork**  
- 🟢 Fully integrated with **Discord Rich Presence**  
- 🚫 Optional: You can disable/enable Discord Rich Presence via a toggle  
- 🔍 Auto-refreshes even when Discord is not running  
- 🎛️ Clean macOS-style user interface  
- 🧊 Built-in error alerts if Discord isn't launched  

---

## 📸 Preview

| Interface | Discord |
|----------|---------|
| ![App Screenshot](./screenshots/interface.png) | ![Discord Screenshot](./screenshots/discord.png) |

> *Album art, song title, album name and artist shown in both the app and your Discord profile.*

---

## 🧱 Tech Stack

- `SwiftUI` for the macOS interface  
- `ScriptingBridge` to communicate with Apple Music  
- [`SwordRPC`](https://github.com/Azoy/SwordRPC) for Discord Rich Presence  
- `Socket.swift` (dependency of SwordRPC)  
- Swift 5.9, macOS 13+ compatible (ARM + Intel)  

---

## 🚀 Installation

### 🧪 Run from Xcode

1. Clone this repository: ```git clone https://github.com/georgionahra/apple-music-rich-presence```
2. Open the `.xcodeproj` in Xcode  
3. Select the "My Mac" target and press Run (⌘R)  

### 📦 Build a .app version

1. In Xcode, go to: **Product > Archive** → then export the `.app`
2. Move the `.app` to `/Applications` and launch it like a native macOS app  

---

## 🛠️ Requirements

- macOS Ventura (13) or later  
- Apple Music app installed and running  
- Discord app installed  
- AppleScript permissions (granted automatically by macOS)

---

## 🧩 Permissions

When launching the app for the first time, macOS may ask for permission to control “Music”.  
Click **OK** — it’s required to fetch the current track information.

---

## ⚠️ Troubleshooting

- ❌ *"Discord is not running"* error: Make sure the Discord app is open  
- ❌ *Rich Presence doesn't show*: Toggle Discord Rich Presence off/on in the app  

💡 For detailed logs: run the app from Xcode and open the debug console (⇧⌘Y)

---

## 📄 License

This project is licensed under the [GNU GPLv3 License](https://www.gnu.org/licenses/gpl-3.0.en.html).

---

## 👑 Credits

Made with passion by Georgio Nahra  
© 2025 — All rights reserved
