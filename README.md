<div align="center">

# Tanto 🗡️

[English](README.md) | [简体中文](README_CN.md)

</div>

**Tanto** is a global efficiency tool designed specifically for Windows developers. Built on AutoHotkey v2.0, it brings the core operational logic of Vim into the global environment while enforcing a **"One-shot"** editing philosophy.

> **💡 Core Philosophy:** Mode switching should not be a burden. Entering a mode is for completing specific atomic tasks (selecting, copying, deleting). Once the task is triggered, the script immediately and automatically returns to editing mode.

---

## 📥 Installation

**No installation required. Works out of the box.**

1. Go to the **[Releases Page](../../releases)**.
2. Download the latest `Tanto.exe`.
3. Double-click to run (Setting it to run on startup is recommended).

> ⚡ **Automated Build**: This project uses GitHub Actions for automated compilation, ensuring the binary you download is perfectly consistent with the source code, transparent, and secure.

---

## ✨ Core Features (v2.0 Updated)

* **⚡ Select on Entry (Default Visual Mode)**
    * Clicking `CapsLock` enters **Visual Mode** by default. Combined with `IJKL`, this allows for instant code selection. No need to press `v` and then move like in traditional Vim.

* **🖱️ Native Immersive Cursor Experience**
    * **Visual Mode**: Cursor becomes a **Crosshair (✚)**, implying precise selection.
    * **Normal Mode**: Cursor becomes a **Four-way Arrow (✥)**, implying rapid movement.
    * *No intrusive pop-ups or bubbles that block your vision. Returns to the native Windows feel.*

* **🎯 One-shot Action**
    * All operations (Copy `c`, Delete `d`, Cut `x`) automatically **release the logic state and return to Insert Mode** immediately after execution. No need to manually press Esc.

* **🤖 Typeout Simulation (With Safety Brake)**
    * Press `t` in Normal Mode to type out the clipboard content character by character (simulating human keystrokes).
    * **Disaster Prevention**: Perfectly bypasses "paste disabled" restrictions in terminals or virtual machines. If the input is incorrect, **hold `Esc` to emergency stop**.

* **📦 Portable Design**
    * Icon resources are automatically packed into the EXE. It is a single file you can take anywhere without worrying about missing resources.

---

## ⌨️ Key Bindings

### 1. Modes & Status

| Key | Mode | Cursor | Description |
| :--- | :--- | :--- | :--- |
| `CapsLock` | **Visual (Default)** | **✚ Crosshair** | Automatically holds Shift while moving (Selecting). |
| `v` | Visual / Normal | **✥ Four-way** | Toggles between "Selection" and "Pure Movement" modes. |
| `Esc` | Edit | **↖ Arrow** | Force quit navigation and return to Edit Mode. |

### 2. Basic Movement (HJKL ++)

| Key | Function | Description |
| :--- | :--- | :--- |
| `i` / `k` / `j` / `l` | Up / Down / Left / Right | Moves with or without selection based on current mode. |
| `u` / `o` | Home / End | Quickly jump to the Start/End of the line. |
| `h` | **High-Impact Select** | Simulates `Shift+Home` x2 + `End`. **Selects the entire current line.** |
| `Ctrl` + `i/k` | Vertical Jump | Moves across 5 lines. |
| `Ctrl` + `j/l` | Horizontal Jump | Moves by Word. |

### 3. Operator Pending

When entering a mode **without movement**, pressing `d` (Delete), `c` (Copy), or `x` (Cut) enters a waiting state (cursor remains unchanged). You can then follow up with these commands:

| Suffix | Action | Typical Scenario |
| :--- | :--- | :--- |
| `h` | **House (Whole Line)** | Operates on the **Whole Line** (Automatically closes gaps). |
| `w` | **Word (Right)** | Operates on the **Right Word**. |
| `b` | **Back (Left)** | Operates on the **Left Word**. |

> **Combo Examples**:
> * `dh`: Delete the entire line.
> * `cw`: Copy the current word.
> * `xb`: Cut the previous word.
>
> **Note**: If movement **HasMoved** (you already selected text), pressing `d/c/x` applies immediately to the **current selection**.

### 4. Utility Functions

* **`t` (Typeout)**: (In Normal Mode) Types clipboard content as keystrokes. **Hold `Esc` to stop.**
* **`Tab`**: Sends a standard Tab key (Retains key function to prevent conflict).
* **`CapsLock + IJKL`**: Can be used as standard arrow keys at any time (Non-VIM logic, pure mapping).
* **`n`**: Sends `End` + `Enter` (Quick new line).

---

## 🛠️ Development & Contribution

If you want to modify the source code or compile it yourself:

1.  Clone the repository:
    ```bash
    git clone [https://github.com/L-Rocket/Tanto.git](https://github.com/L-Rocket/Tanto.git)
    ```
2.  Ensure [AutoHotkey v2.0+](https://www.autohotkey.com/) is installed.
3.  Run `tanto.ahk` directly for debugging.
4.  **Icons**: Located in the `icon/assets/` directory. The compilation script references them automatically.

---

## ⚠️ FAQ

* **Q: Why doesn't pressing `c` do anything?**
    * A: If nothing is selected, `c` enters the "Operator Pending" state (waiting for `h/w/b`). If you want to force copy the current line, use `ch`.

* **Q: The Typeout function won't stop!**
    * A: **Hold the Esc key**. The script detects this and will force an interrupt of the loop.

* **Q: It doesn't work in some games or Admin software?**
    * A: Please try running the script/EXE as "Administrator". Standard user permissions in AHK cannot control high-privileged windows.

---

## 📄 License

This project is open-sourced under the **GNU GPLv3** license.
[GNU General Public License v3.0](LICENSE)