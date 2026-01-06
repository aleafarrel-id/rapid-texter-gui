<div align="center">

# 🚀 Rapid Texter GUI

![C++](https://img.shields.io/badge/C++-17-00599C?style=for-the-badge&logo=c%2B%2B&logoColor=white)
![Qt](https://img.shields.io/badge/Qt-6.8-41CD52?style=for-the-badge&logo=qt&logoColor=white)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20Linux-lightgrey?style=for-the-badge)
![License](https://img.shields.io/badge/License-MIT-green?style=for-the-badge)

**Test your finger speed and mental accuracy with a modern interface.** Rapid Texter now features a stunning **GUI (Graphical User Interface)**, smooth animations, and a more intuitive user experience.

[Features](#-key-features) • [Download](#-download--installation) • [Build](#%EF%B8%8F-build-from-source) • [Contribute](#-license)

</div>

---

## ⚡ Key Features

* **✨ Modern GUI:** Built with **Qt/QML 6.8**, delivering an aesthetic and responsive interface.
* **🌐 Multi-Language:** Available in Indonesian & English modes.
* **💻 Programmer Mode:** Practice typing symbols and coding syntax (`#include`, `std::vector`, etc.).
* **📊 Visual Statistics:** Monitor WPM (*Words Per Minute*), Accuracy, and Progress Charts with attractive visuals.
* **🎨 Themes & Animations:** Smooth menu transitions and eye-comfortable interface design.
* **🎵 Sound Effects:** Satisfying audio feedback when typing correctly (ding!) or incorrectly.
* **🖱️ Mouse & Keyboard Friendly:** Navigate menus using the mouse or stick to the keyboard for speed.

---

## 📥 Download & Installation

The easiest way to use Rapid Texter is by downloading the provided installer.

### 🪟 Windows (Recommended)
1. Go to the latest **[Releases](https://github.com/aleafarrel-id/rapidtexter-gui/releases)** page.
2. Download the `RapidTexterGUI_win64-Setup.exe` file.
3. Run the `.exe` file and follow the installation instructions.
4. The application is ready to use! A shortcut will be available on your Desktop and Start Menu.

### 🐧 Linux (AppImage)
1. Download the `.AppImage` file from the Releases page.
2. Grant execution permission: `chmod +x RapidTexterGUI-x86_64.AppImage`.
3. Run the application!

---

## 🎮 How to Use

### 1. Main Menu
An elegant start screen allows you to choose your mode:
- **Play Game**: Start a new game.
- **History**: View your typing speed progress charts.
- **Settings**: Adjust sound effects and other preferences.

### 2. Game Customization
Before starting, you can configure:
- **Language**: Indonesia (ID) or English (EN).
- **Time**: 15s, 30s, 60s, or Custom.
- **Mode**:
    - **Manual**: Free WPM target.
    - **Campaign**: Progressive levels (Easy, Medium, Hard, Programmer).

### 3. Gameplay
Type the text that appears on the screen.
- **Green**: Correct letter.
- **Red**: Incorrect letter.
- **Backspace**: Can be used to correct previous mistakes.

### 4. Results & Evaluation
At the end of the session, you will see a result card displaying:
- **Big WPM**: Main speed score.
- **Accuracy**: Typing precision percentage.
- **Chart**: Comparison with previous sessions (if available).

---

## 🛠️ Build from Source

For developers who want to contribute or modify the source code.

### Prerequisites
1.  **Qt 6.8** (Install via Qt Online Installer, select **Qt Quick**, **Qt Quick Controls 2**, **Qt Multimedia** components).
2.  **C++ Compiler** (MSVC 2019+ or latest GCC/Clang).
3.  **CMake** version 3.16 or higher.

### Build Steps

Clone this repository:
```bash
git clone https://github.com/aleafarrel-id/rapidtexter-gui.git
cd rapidtexter-gui
```

Build using CMake:

```bash
# 1. Configure (Ensure Qt 6.8 path is correct/detected)
cmake -S . -B build

# 2. Compile
cmake --build build --config Release
```

### Run Application
The build result will be in the `build/Release/` (Windows) or `build/` (Linux) folder.

---

## 📂 Project Structure

```text
rapidtexter-gui/
├── assets/             # Word banks, fonts, icons, sfx
├── src/                # C++ Backend logic (GameBackend, Stats, etc.)
├── include/            # Header files C++
├── qml/                # User Interface (Qt Quick/QML)
│   ├── components/     # Reusable UI components (Button, Card, etc.)
│   └── pages/          # Screen pages (Menu, Game, Result)
├── resources/          # Resource definition (.rc and icons)
├── CMakeLists.txt      # CMake Build Configuration
└── README.md           # This documentation
```

## 📜 License

This project is licensed under the **MIT License**. Free to use, modify, and distribute.

---
<div align="center">
  Developed 2025 by Alea Farrel & Team.
</div>
