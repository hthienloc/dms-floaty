# Floaty

Pin reference images, screenshots, and PDFs on top of your workspace.

<img src="screenshot.png" width="400" alt="Screenshot">

## Install

[<kbd>Install Now</kbd>](dms://plugin/install/floaty)

Or manually:
```bash
git clone https://github.com/hthienloc/dms-floaty ~/.config/DankMaterialShell/plugins/floaty
```

## Features

- **Float from anywhere** - Clipboard, file picker, drag & drop, or URL
- **Multi-format support** - PNG, JPG, WebP, BMP, SVG, PDF (page selection)
- **Smart layout** - Auto-tiling prevents overlapping
- **Always on top** - Windows stay visible while you work
- **IPC ready** - Script-friendly commands for automation

## Usage

| Action | Result |
|--------|--------|
| Drag onto icon | Quick float |
| Left click | Open menu |
| Right click | Paste from clipboard |
| Scroll | Resize image |
| Middle click | Close |

## IPC Commands

```bash
dms ipc call floaty floatFromClipboard
dms ipc call floaty closeAllWindows
```

## Requirements

- `poppler-utils` - PDF conversion (`pdftocairo`, `pdfinfo`)

## License

MIT