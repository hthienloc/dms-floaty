import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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

    onPluginDataChanged: {
        if (pluginData) {
            spawnPosition = pluginData.spawnPosition || "center";
            maxHeight = pluginData.maxHeight || 0;
            updatePosition();
        }
    }
    
    property bool isMinimized: false
    property real targetWidth: initialWidth
    property real targetHeight: 1
    property bool imageLoaded: false

    onTargetWidthChanged: updatePosition()
    onTargetHeightChanged: updatePosition()

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

    function updatePosition() {
        xPos = xPosForPosition(spawnPosition, targetWidth, window.screen.width);
        yPos = yPosForPosition(spawnPosition, targetHeight, window.screen.height);
    }

    // The Drag Engine
    Item {
        id: dragTarget
        x: window.xPos
        y: window.yPos
        onXChanged: { if (dragArea.drag.active) window.xPos = x }
        onYChanged: { if (dragArea.drag.active) window.yPos = y }
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

        // Image View - Fixed size inside container to prevent shrinking effect
        Image {
            id: img
            source: window.imageSource
            width: window.targetWidth - 10
            height: window.targetHeight - 10
            anchors.centerIn: parent
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            opacity: window.imageLoaded ? 1 : 0
            visible: opacity > 0
            
            onStatusChanged: {
                if (status === Image.Ready) {
                    let ratio = implicitHeight / implicitWidth;
                    let calcHeight = window.targetWidth * ratio;
                    if (window.maxHeight > 0 && calcHeight > window.maxHeight) {
                        window.targetHeight = window.maxHeight;
                    } else {
                        window.targetHeight = calcHeight;
                    }
                    window.imageLoaded = true;
                    updatePosition();
                }
            }
        }

        // Minimized Icon
        DankIcon {
            id: cloudIcon
            name: "cloud"
            anchors.centerIn: parent
            size: Theme.iconSize
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
                let newWidth = Math.max(100, Math.min(2000, startWidth * scale));
                let ratio = img.implicitHeight / img.implicitWidth;
                window.targetWidth = newWidth;
                window.targetHeight = newWidth * ratio;
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
                if (window.isMinimized) return;
                
                // Use a more continuous scaling factor for touchpad precision
                // 120 is the standard mouse wheel delta. 
                // We use pow(1.1, delta/120) to make it smooth and match the 1.1/0.9 feeling for mice.
                let scaleFactor = Math.pow(1.1, wheel.angleDelta.y / 120.0);
                let newWidth = Math.max(100, Math.min(2000, window.targetWidth * scaleFactor));
                let ratio = img.implicitHeight / img.implicitWidth;
                
                window.targetWidth = newWidth;
                window.targetHeight = newWidth * ratio;
            }
        }

        // Move states and transitions here
        states: [
            State {
                name: "minimized"
                when: window.isMinimized
                PropertyChanges { target: window; width: 56; height: 56 }
                PropertyChanges { target: container; radius: 28; color: Theme.primary; border.width: 0 }
                PropertyChanges { target: img; opacity: 0 }
                PropertyChanges { target: cloudIcon; opacity: 1 }
            }
        ]

        transitions: [
            Transition {
                from: ""; to: "minimized"
                ParallelAnimation {
                    NumberAnimation {
                        target: window; properties: "width,height"
                        duration: 80
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.expressiveCurves.emphasizedDecel
                    }
                    NumberAnimation {
                        target: container; properties: "radius"
                        duration: 80
                        easing.type: Easing.OutCubic
                    }
                    ColorAnimation {
                        target: container
                        duration: 80
                    }
                    NumberAnimation {
                        target: img; property: "opacity"
                        duration: 40
                    }
                    NumberAnimation {
                        target: cloudIcon; property: "opacity"
                        duration: 40
                    }
                }
            },
            Transition {
                from: "minimized"; to: ""
                ParallelAnimation {
                    NumberAnimation {
                        target: window; properties: "width,height"
                        duration: 120
                        easing.type: Easing.BezierSpline
                        easing.bezierCurve: Theme.expressiveCurves.emphasized
                    }
                    NumberAnimation {
                        target: container; properties: "radius"
                        duration: 120
                        easing.type: Easing.OutCubic
                    }
                    ColorAnimation {
                        target: container
                        duration: 120
                    }
                    NumberAnimation {
                        target: img; property: "opacity"
                        duration: 120
                    }
                    NumberAnimation {
                        target: cloudIcon; property: "opacity"
                        duration: 60
                    }
                }
            }
        ]
    }
}
