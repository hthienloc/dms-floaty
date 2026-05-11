import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects as GE
import Quickshell
import Quickshell.Wayland
import qs.Common
import qs.Services
import qs.Widgets

PanelWindow {
    id: window
    color: "transparent"
    
    signal closing()
    
    property string imageSource: ""
    property bool isPinned: true 
    property int initialWidth: 400
    
    // Settings from plugin
    property var pluginData: ({})
    readonly property bool autoMinimize: pluginData.autoMinimize ?? false
    readonly property int minimizeDelay: pluginData.minimizeDelay ?? 3000
    readonly property int borderWidth: pluginData.borderWidth ?? 2
    readonly property string borderColor: pluginData.borderColor ?? "outlineVariant"
    property string spawnPosition: "center"
    property int maxHeight: 0
    property var plugin: null

    onPluginDataChanged: {
        if (pluginData) {
            spawnPosition = pluginData.spawnPosition || "center";
            maxHeight = pluginData.maxHeight || 0;
            updateSize();
        }
    }
    
    property bool isMinimized: false
    property real targetWidth: initialWidth
    property real targetHeight: 1
    property bool imageLoaded: false
    property bool manuallyMoved: false

    onTargetWidthChanged: if (!manuallyMoved) updatePosition()
    onTargetHeightChanged: if (!manuallyMoved) updatePosition()

    // Position control
    property int xPos: 400
    property int yPos: 400

    // Quickshell LayerShell Configuration
    anchors { top: true; left: true }
    WlrLayershell.namespace: "dms-floaty"
    WlrLayershell.layer: window.isPinned ? WlrLayershell.Overlay : WlrLayershell.Bottom
    WlrLayershell.exclusiveZone: -1
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
    
    WlrLayershell.margins {
        left: xPos
        top: yPos
    }

    // Dynamic width/height handled by states in container
    implicitWidth: targetWidth
    implicitHeight: targetHeight

    Timer {
        id: minimizeTimer
        interval: window.minimizeDelay
        repeat: false
        onTriggered: window.isMinimized = true
    }

    Component.onCompleted: {
        if (window.autoMinimize) {
            minimizeTimer.start();
        }
        updatePosition();
    }

    function yPosForPosition(pos, winHeight, screenHeight) {
        const padding = 8;
        switch (pos) {
            case "top": case "top-left": case "top-right": return padding;
            case "bottom": case "bottom-left": case "bottom-right": return screenHeight - winHeight - padding;
            default: return (screenHeight - winHeight) / 2;
        }
    }

    function xPosForPosition(pos, winWidth, screenWidth) {
        const padding = 8;
        switch (pos) {
            case "left": case "top-left": case "bottom-left": return padding;
            case "right": case "top-right": case "bottom-right": return screenWidth - winWidth - padding;
            default: return (screenWidth - winWidth) / 2;
        }
    }

    readonly property int minimizedSize: 40

    function updatePosition() {
        let newX = xPosForPosition(spawnPosition, targetWidth, window.screen.width);
        let newY = yPosForPosition(spawnPosition, targetHeight, window.screen.height);



        let avoidStacking = true;
        if (plugin && plugin.pluginData && plugin.pluginData.avoidStacking !== undefined) {
            avoidStacking = plugin.pluginData.avoidStacking;
        }

        if (avoidStacking && !manuallyMoved && plugin && plugin.openWindows) {
            let padding = 8;
            let currentWindows = plugin.openWindows;
            let attempts = 0;
            let maxAttempts = 50; 
            
            let overlapping = true;
            while (overlapping && attempts < maxAttempts) {
                overlapping = false;
                for (let i = 0; i < currentWindows.length; i++) {
                    let other = currentWindows[i];
                    if (!other || other === window || other.isMinimized) continue;
                    
                    let ox = other.xPos;
                    let oy = other.yPos;
                    let ow = other.targetWidth;
                    let oh = other.targetHeight;

                    // Standard AABB overlap check with padding
                    let isOverlapping = !(newX + targetWidth + padding <= ox || 
                                          newX >= ox + ow + padding ||
                                          newY + targetHeight + padding <= oy ||
                                          newY >= oy + oh + padding);
                    
                    if (isOverlapping) {
                        // Vertical stacking direction depends on whether we started at top or bottom
                        if (spawnPosition.includes("bottom")) {
                            // Stack UPWARDS
                            newY = oy - targetHeight - padding;
                            
                            // If we hit the top, move to a new column
                            if (newY < padding) {
                                newY = yPosForPosition(spawnPosition, targetHeight, window.screen.height);
                                if (spawnPosition.includes("right")) newX = ox - targetWidth - padding;
                                else newX = ox + ow + padding;
                            }
                        } else {
                            // Stack DOWNWARDS (default for top or center)
                            newY = oy + oh + padding;
                            
                            // If we hit the bottom, move to a new column
                            if (newY + targetHeight > window.screen.height - padding) {
                                newY = yPosForPosition(spawnPosition, targetHeight, window.screen.height);
                                if (spawnPosition.includes("right")) newX = ox - targetWidth - padding;
                                else newX = ox + ow + padding;
                            }
                        }
                        overlapping = true;
                        break; 
                    }
                }
                attempts++;
            }
        }

        if (window.isMinimized) {
            let centerX = newX + targetWidth / 2;
            let centerY = newY + targetHeight / 2;
            if (centerX > window.screen.width / 2) newX += (targetWidth - minimizedSize);
            if (centerY > window.screen.height / 2) newY += (targetHeight - minimizedSize);
        }


        // Final safety clamp to ensure padding from all edges
        let edgePadding = 8;
        newX = Math.max(edgePadding, Math.min(window.screen.width - targetWidth - edgePadding, newX));
        newY = Math.max(edgePadding, Math.min(window.screen.height - targetHeight - edgePadding, newY));

        xPos = newX;
        yPos = newY;
    }

    function updateSize() {
        if (img.status !== Image.Ready) return;

        let iw = img.implicitWidth;
        let ih = img.implicitHeight;
        if (iw <= 0 || ih <= 0) return;

        let ratio = iw / ih;
        let w = initialWidth;
        let h = w / ratio;

        if (maxHeight > 0 && h > maxHeight) {
            h = maxHeight;
            w = h * ratio;
        }

        targetWidth = w;
        targetHeight = h;
        
        if (!manuallyMoved) {
            updatePosition();
        }
    }

    // The Drag Engine
    Item {
        id: dragTarget
        x: window.xPos
        y: window.yPos
        onXChanged: { 
            if (dragArea.drag.active) {
                window.xPos = x;
                window.manuallyMoved = true;
            }
        }
        onYChanged: { 
            if (dragArea.drag.active) {
                window.yPos = y;
                window.manuallyMoved = true;
            }
        }
    }

    StyledRect {
        id: container
        anchors.fill: parent
        radius: Theme.cornerRadius
        color: Theme.surfaceContainer
        border.color: window.borderColor === "primary" ? Theme.primary : 
                      window.borderColor === "surfaceContainerHighest" ? Theme.surfaceContainerHighest :
                      window.borderColor === "transparent" ? "transparent" : Theme.outlineVariant
        border.width: window.borderWidth
        clip: true
        antialiasing: true

        SequentialAnimation {
            id: opacityToClose
            NumberAnimation { target: container; property: "opacity"; to: 0; duration: 150; easing.type: Easing.OutCubic }
            ScriptAction { script: { window.closing(); window.destroy(); } }
        }

        // Image View - Fills container and aligns with border
        Image {
            id: img
            source: window.imageSource
            anchors.fill: parent
            anchors.margins: window.borderWidth
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            antialiasing: true
            opacity: window.imageLoaded ? 1 : 0
            visible: opacity > 0

            layer.enabled: true
            layer.effect: GE.OpacityMask {
                maskSource: Rectangle {
                    width: img.width
                    height: img.height
                    radius: Math.max(0, Theme.cornerRadius - window.borderWidth)
                    visible: false
                    antialiasing: true
                }
            }

            onStatusChanged: {
                if (status === Image.Ready) {
                    updateSize();
                    window.imageLoaded = true;
                }
            }
        }

        // Minimized Icon
        DankIcon {
            id: cloudIcon
            name: "cloud"
            anchors.centerIn: parent
            size: Theme.iconSizeSmall
            color: Theme.onPrimary
            opacity: 0
            visible: opacity > 0
        }

        // Touchpad Pinch Support
        PinchHandler {
            id: pinchHandler
            target: null
            property real startWidth: 400
            onActiveChanged: {
                if (active) startWidth = window.targetWidth;
            }
            onScaleChanged: {
                if (img.implicitWidth <= 0 || img.implicitHeight <= 0) return;
                let newWidth = Math.max(100, Math.min(2000, startWidth * scale));
                let ratio = img.implicitWidth / img.implicitHeight;
                window.targetWidth = newWidth;
                window.targetHeight = newWidth / ratio;
            }
        }

        // Interactions
        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeAllCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

            drag.target: dragTarget
            drag.axis: Drag.XAndYAxis
            drag.threshold: 0

            onEntered: {
                minimizeTimer.stop();
                window.isMinimized = false;
            }

            onExited: {
                if (window.autoMinimize && !drag.active) {
                    minimizeTimer.restart();
                }
            }

            onPressed: function(mouse) {
                if (mouse.button === Qt.RightButton) {
                    window.isMinimized = !window.isMinimized;
                } else if (mouse.button === Qt.MiddleButton) {
                    opacityToClose.start();
                }
            }

            onWheel: (wheel) => {
                if (window.isMinimized || img.implicitWidth <= 0 || img.implicitHeight <= 0) return;

                let scaleFactor = Math.pow(1.1, wheel.angleDelta.y / 120.0);
                let oldWidth = window.targetWidth;
                let oldHeight = window.targetHeight;
                let newWidth = Math.max(100, Math.min(2000, oldWidth * scaleFactor));
                let ratio = img.implicitWidth / img.implicitHeight;
                let newHeight = newWidth / ratio;

                // Directional resize logic:
                // We keep the corner closest to the screen edge fixed.
                let centerX = window.xPos + oldWidth / 2;
                let centerY = window.yPos + oldHeight / 2;
                let screenWidth = window.screen.width;
                let screenHeight = window.screen.height;

                // Adjust X: if center is in right half, keep right edge fixed (move x left)
                if (centerX > screenWidth / 2) {
                    window.xPos -= (newWidth - oldWidth);
                } 
                // else: center is in left half, keep left edge fixed (do nothing to x)

                // Adjust Y: if center is in bottom half, keep bottom edge fixed (move y up)
                if (centerY > screenHeight / 2) {
                    window.yPos -= (newHeight - oldHeight);
                }
                // else: center is in top half, keep top edge fixed (do nothing to y)

                window.targetWidth = newWidth;
                window.targetHeight = newHeight;
            }
        }

        // Move states and transitions here
        states: [
            State {
                name: "minimized"
                when: window.isMinimized
                PropertyChanges { target: window; width: minimizedSize; height: minimizedSize }
                PropertyChanges { target: container; radius: minimizedSize / 2; color: Theme.primary; border.width: 0; opacity: 0.5 }
                PropertyChanges { target: img; opacity: 0 }
                PropertyChanges { target: cloudIcon; opacity: 1 }
            }
        ]

        transitions: [
            Transition {
                from: ""; to: "minimized"
                SequentialAnimation {
                    NumberAnimation {
                        target: container
                        property: "opacity"
                        to: 0
                        duration: 70
                        easing.type: Easing.OutQuad
                    }
                    ScriptAction {
                        script: {
                            let oldWidth = window.targetWidth;
                            let oldHeight = window.targetHeight;
                            let centerX = window.xPos + oldWidth / 2;
                            let centerY = window.yPos + oldHeight / 2;
                            let screenWidth = window.screen.width;
                            let screenHeight = window.screen.height;

                            if (centerX > screenWidth / 2) window.xPos += (oldWidth - minimizedSize);
                            if (centerY > screenHeight / 2) window.yPos += (oldHeight - minimizedSize);
                        }
                    }
                    PropertyAction { 
                        targets: [window, container, img, cloudIcon]
                        properties: "width,height,radius,color,border.width,opacity"
                    }
                    NumberAnimation {
                        target: container
                        property: "opacity"
                        to: 0.5
                        duration: 80
                        easing.type: Easing.InQuad
                    }
                }
            },
            Transition {
                from: "minimized"; to: ""
                SequentialAnimation {
                    NumberAnimation {
                        target: container
                        property: "opacity"
                        to: 0
                        duration: 70
                        easing.type: Easing.OutQuad
                    }
                    ScriptAction {
                        script: {
                            let oldWidth = window.targetWidth;
                            let oldHeight = window.targetHeight;
                            let centerX = window.xPos + minimizedSize / 2;
                            let centerY = window.yPos + minimizedSize / 2;
                            let screenWidth = window.screen.width;
                            let screenHeight = window.screen.height;

                            if (centerX > screenWidth / 2) window.xPos -= (oldWidth - minimizedSize);
                            if (centerY > screenHeight / 2) window.yPos -= (oldHeight - minimizedSize);
                        }
                    }
                    PropertyAction { 
                        targets: [window, container, img, cloudIcon]
                        properties: "width,height,radius,color,border.width,opacity"
                    }
                    NumberAnimation {
                        target: container
                        property: "opacity"
                        to: 1
                        duration: 80
                        easing.type: Easing.InQuad
                    }
                }
            }
        ]    }
}
