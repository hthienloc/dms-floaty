# Floaty for DMS

A minimalist reference image plugin for DankMaterialShell. Float images on top of your windows with ease.

![Floaty Screenshot](screenshot.png)

## Features
- **Float from Clipboard**: Instantly pin images from your clipboard.
- **Select File**: Import and pin image files from your local folders.
- **Always on Top**: Images stay visible while you work.
- **Smart Auto-Minimize**: Automatically shrinks to an icon when idle to save screen space.
- **Dynamic Resizing**: Scale images using your mouse wheel.
- **Drag & Move**: Reposition images anywhere on your screen.
- **Smart Bar Icon**: The pill icon changes to your accent color when images are active.

## Controls
- **Left Click + Drag**: Move the floating image.
- **Scroll Wheel / Pinch Gesture**: Resize (Zoom) the image.
- **Middle Click**: Toggle minimized state (manual shrink/expand).
- **Right Click Image**: Close the image window.
- **Right Click Bar Icon**: Instant paste from clipboard.
- **Left Click Bar Icon**: Open control menu (Popout).

## IPC Commands
Floaty exposes commands that you can bind to keyboard shortcuts in your window manager (e.g., Niri, Hyprland):

```bash
# Float current clipboard image
dms ipc call floaty floatFromClipboard

# Open file selector to float
dms ipc call floaty selectFileAndFloat
```

### Example: Screenshot to Floaty (Niri)
Add this to your `config.kdl` to automatically float a screenshot:
```kdl
bindings {
    Print { 
        spawn "sh" "-c" "grim -g \"$(slurp)\" - | wl-copy && dms ipc call floaty floatFromClipboard"; 
    }
}
```

## Notes
> [!WARNING]
> **Touchpad Scaling**: Touchpad gestures (pinch and scroll) might vary in sensitivity across different Wayland compositors. Using a mouse scroll wheel provides the most consistent precision.

## Requirements
- `wl-paste` (Wayland) or `xclip` (X11) for clipboard support.
- `kdialog` for file selection.

## Installation
1. Clone this repository into `~/.config/DankMaterialShell/plugins/`:
   ```bash
   git clone https://github.com/hthienloc/dms-floaty floaty
   ```
2. Reload DMS or use the IPC command:
   ```bash
   dms ipc plugins reload floaty
   ```

## Credits
- Inspired by [Kasasa](https://flathub.org/en/apps/io.github.kelvinnovais.Kasasa).
