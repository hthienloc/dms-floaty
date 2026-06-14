import QtQuick
import Quickshell
import Quickshell.Io
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import qs.Modals.Common
import qs.Modals.FileBrowser
import "./dms-common"

PluginComponent {
    id: root

    pluginId: "floaty"
    pluginService: PluginService

    readonly property bool showHints: root.pluginData.showHints ?? true
    property int localWindowCount: 0
    property var openWindows: []
    property var floatyWindowComponent: null

    Component.onCompleted: {
        if (!pluginService.pluginInstances[pluginId]) {
            const newInstances = Object.assign({}, pluginService.pluginInstances);
            newInstances[pluginId] = root;
            pluginService.pluginInstances = newInstances;
        }
    }

    Component.onDestruction: {
        if (pluginService.pluginInstances[pluginId] === root) {
            const newInstances = Object.assign({}, pluginService.pluginInstances);
            delete newInstances[pluginId];
            pluginService.pluginInstances = newInstances;
        }
    }

    FileBrowserModal {
        id: fileBrowserModal
        browserTitle: "Select Image or PDF"
        browserIcon: "image"
        fileExtensions: ["*.png", "*.jpg", "*.jpeg", "*.webp", "*.gif", "*.bmp", "*.svg", "*.pdf"]
        onFileSelected: path => {
            root.spawnWindow("file://" + path);
            close();
        }
    }

    InputModal {
        id: inputModal
    }

    IpcHandler {
        target: "floaty"

        function floatFromClipboard(): string {
            root.floatFromClipboard();
            return "SUCCESS";
        }

        function selectFileAndFloat(): string {
            root.selectFileAndFloat();
            return "SUCCESS";
        }

        function closeAllWindows(): string {
            root.closeAllWindows();
            return "SUCCESS";
        }

        function floatFromUrl(url: string): string {
            root.spawnWindow(url);
            return "SUCCESS";
        }

        function toggleMinimizeAll(): string {
            root.toggleMinimizeAll();
            return "SUCCESS";
        }

        function minimizeAll(): string {
            root.minimizeAll();
            return "SUCCESS";
        }

        function expandAll(): string {
            root.expandAll();
            return "SUCCESS";
        }
    }

    function floatFromClipboard() {
        root.smartPaste();
    }

    function smartPaste() {
        const timestamp = Date.now();
        const tempPath = "/tmp/dms_floaty_" + timestamp + ".png";
        
        const checkCmd = `
            if wl-paste -t image/png > ${tempPath} 2>/dev/null || xclip -selection clipboard -t image/png -o > ${tempPath} 2>/dev/null; then
                echo "IMAGE:${tempPath}"
            else
                TEXT=$(wl-paste -n 2>/dev/null || xclip -selection clipboard -o 2>/dev/null)
                if [ -n "$TEXT" ]; then
                    echo "TEXT:$TEXT"
                else
                    echo "EMPTY"
                fi
            fi
        `;

        Proc.runCommand(
            "smart-paste",
            ["sh", "-c", checkCmd],
            function(stdout, exitCode) {
                const output = stdout.trim();
                if (output.startsWith("IMAGE:")) {
                    const path = output.substring(6);
                    spawnWindow("file://" + path);
                } else if (output.startsWith("TEXT:")) {
                    const text = output.substring(5).trim();
                    if (text.startsWith("http://") || text.startsWith("https://") || text.startsWith("/")) {
                        spawnWindow(text.startsWith("/") ? "file://" + text : text);
                    } else {
                        ToastService.showError("Clipboard text is not a valid URL or path.");
                    }
                } else {
                    ToastService.showError("No valid image, URL, or path in clipboard.");
                }
            },
            0
        );
    }

    function raiseWindow(win) {
        if (!win) return;
        root.openWindows.forEach(w => {
            if (w && typeof w.isTop !== 'undefined') {
                w.isTop = (w === win);
            }
        });
    }

    function selectFileAndFloat() {
        fileBrowserModal.open();
    }

    function closeAllWindows() {
        const windows = [...root.openWindows];
        windows.forEach(win => {
            if (win && typeof win.close === "function") {
                win.close();
            } else if (win) {
                win.destroy();
            }
        });
    }

    function toggleMinimizeAll() {
        if (root.openWindows.length === 0) return;
        let anyExpanded = root.openWindows.some(win => !win.isMinimized);
        root.openWindows.forEach(win => {
            win.isMinimized = anyExpanded;
        });
    }

    function minimizeAll() {
        root.openWindows.forEach(win => {
            win.isMinimized = true;
        });
    }

    function expandAll() {
        root.openWindows.forEach(win => {
            win.isMinimized = false;
        });
    }

    function spawnWindow(source) {
        if (!source) return;

        if (source.startsWith("file://")) {
            let path = source.substring(7);
            
            if (path.toLowerCase().endsWith(".pdf")) {
                Proc.runCommand("pdf-info", ["pdfinfo", path], function(stdout, exitCode) {
                    if (exitCode !== 0) {
                        ToastService.showError("Failed to read PDF info. Make sure poppler-utils is installed.");
                        return;
                    }
                    
                    let totalPages = 1;
                    let match = stdout.match(/Pages:\s+(\d+)/);
                    if (match) totalPages = parseInt(match[1]);

                    const parsePageSelection = function(input) {
                        const pages = [];
                        const parts = input.trim().split(/\s+/);
                        
                        for (let part of parts) {
                            part = part.trim();
                            if (!part) continue;

                            if (part.includes("-")) {
                                const range = part.split("-");
                                if (range.length === 2) {
                                    const start = parseInt(range[0]);
                                    const end = parseInt(range[1]);
                                    if (!isNaN(start) && !isNaN(end) && start <= end && start >= 1 && end <= totalPages) {
                                        for (let i = start; i <= end; i++) {
                                            pages.push(i);
                                        }
                                    }
                                }
                            } else {
                                const page = parseInt(part);
                                if (!isNaN(page) && page >= 1 && page <= totalPages && !pages.includes(page)) {
                                    pages.push(page);
                                }
                            }
                        }
                        
                        return pages.sort((a, b) => a - b);
                    };

                    const convertPagesSequentially = function(pages, index) {
                        if (index >= pages.length) return;
                        
                        const page = pages[index];
                        const timestamp = Date.now();
                        const tempBase = "/tmp/dms_floaty_pdf_" + timestamp + "_" + page;
                        const tempPng = tempBase + ".png";
                        
                        Proc.runCommand("pdf-convert", ["pdftocairo", "-png", "-singlefile", "-f", "" + page, "-l", "" + page, path, tempBase], function(stdout, exitCode) {
                            if (exitCode === 0) {
                                root._spawnWindow("file://" + tempPng);
                            } else {
                                ToastService.showError("Failed to convert PDF page " + page);
                            }
                            if (index < pages.length - 1) {
                                Qt.callLater(function() {
                                    convertPagesSequentially(pages, index + 1);
                                });
                            }
                        });
                    };

                    if (totalPages > 1) {
                        inputModal.showWithOptions({
                            title: "Floaty PDF",
                            message: "Enter pages: single (1), range (1-3), or list (1 3 5)",
                            initialText: "1",
                            onConfirm: function(text) {
                                const pages = parsePageSelection(text);
                                if (pages.length === 0) {
                                    ToastService.showError("Invalid page selection.");
                                    return;
                                }
                                
                                ToastService.showInfo("Opening " + pages.length + " page(s)...");
                                convertPagesSequentially(pages, 0);
                            }
                        });
                    } else {
                        const timestamp = Date.now();
                        const tempBase = "/tmp/dms_floaty_pdf_" + timestamp + "_1";
                        const tempPng = tempBase + ".png";
                        Proc.runCommand("pdf-convert", ["pdftocairo", "-png", "-singlefile", "-f", "1", "-l", "1", path, tempBase], function(stdout, exitCode) {
                            if (exitCode === 0) {
                                root._spawnWindow("file://" + tempPng);
                            } else {
                                ToastService.showError("Failed to convert PDF page 1");
                            }
                        });
                    }
                });
                return;
            }

            Proc.runCommand("validate-image", ["file", "-b", path], function(stdout, exitCode) {
                const output = stdout.toLowerCase();
                if (exitCode !== 0 || output.includes("empty") || !output.includes("image")) {
                    ToastService.showError("Invalid or corrupted image file.");
                    return;
                }

                let w = 0, h = 0;
                let re = /(\d+)\s*x\s*(\d+)/g;
                let match;
                while ((match = re.exec(stdout)) !== null) {
                    w = parseInt(match[1]);
                    h = parseInt(match[2]);
                }

                if (w > 0 && h > 0) {
                    const minSize = root.pluginData.minImageSize || 16;
                    if (w < minSize || h < minSize) {
                        ToastService.showError("Image is too small (" + w + "x" + h + "). Minimum: " + minSize + "px");
                        return;
                    }
                }
                
                root._spawnWindow(source);
            });
        } else {
            root._spawnWindow(source);
        }
    }

    function _spawnWindow(source) {
        if (!root.floatyWindowComponent) {
            root.floatyWindowComponent = Qt.createComponent(Qt.resolvedUrl("FloatyWindow.qml"));
        }
        const component = root.floatyWindowComponent;

        const initialWidth = root.pluginService.loadPluginData("floaty", "initialScale", 400);
        const spawnPosition = root.pluginService.loadPluginData("floaty", "spawnPosition", "center");

        const createWin = function() {
            const win = component.createObject(root, {
                imageSource: source,
                spawnPosition: spawnPosition,
                initialWidth: initialWidth,
                pluginData: root.pluginData,
                plugin: root
            });

            if (win !== null) {
                root.localWindowCount++;
                root.openWindows = [...root.openWindows, win];
                root.raiseWindow(win);

                win.closing.connect(function() {
                    root.localWindowCount--;
                    root.openWindows = root.openWindows.filter(w => w !== win);
                });
            } else {
                ToastService.showError("Failed to float image.");
            }
        };

        if (component.status === Component.Ready) {
            createWin();
        } else if (component.status === Component.Error) {
            console.error("Error loading window component:", component.errorString());
        } else {
            component.statusChanged.connect(function() {
                if (component.status === Component.Ready) createWin();
            });
        }
    }
}
