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
    
    property bool isMinimized: false
    property real targetWidth: initialWidth
    property real targetHeight: 300

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
        left: window.xPos
        top: window.yPos
    }

    // Dynamic width/height handled by states in container
    width: targetWidth
    height: targetHeight

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

        // Initial centering based on default size
        window.xPos = (window.screen.width - window.width) / 2;
        window.yPos = (window.screen.height - window.height) / 2;
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
        border.color: Theme.outlineVariant
        border.width: 1
        clip: true
        antialiasing: true

        // Image View - Fixed size inside container to prevent shrinking effect
        Image {
            id: img
            source: window.imageSource
            width: window.targetWidth - 10
            height: window.targetHeight - 10
            anchors.centerIn: parent
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            opacity: 1
            visible: opacity > 0
            
            onStatusChanged: {
                if (status === Image.Ready) {
                    let ratio = implicitHeight / implicitWidth;
                    window.targetHeight = window.targetWidth * ratio;

                    // Final centering once dimensions are known
                    window.xPos = (window.screen.width - window.targetWidth) / 2;
                    window.yPos = (window.screen.height - window.targetHeight) / 2;
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

            onPressed: (mouse) => {
                if (mouse.button === Qt.RightButton) {
                    window.closing();
                    window.destroy();
                } else if (mouse.button === Qt.MiddleButton) {
                    window.isMinimized = !window.isMinimized;
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
                        duration: Theme.variantDuration(100, false)
                        easing.type: Easing.OutCubic 
                    }
                    NumberAnimation { 
                        target: container; properties: "radius"
                        duration: Theme.variantDuration(100, false)
                        easing.type: Easing.InOutQuad 
                    }
                    ColorAnimation { 
                        target: container
                        duration: Theme.variantDuration(100, false) 
                    }
                    NumberAnimation { 
                        target: img; property: "opacity"
                        duration: Theme.variantDuration(40, false) 
                    }
                    NumberAnimation { 
                        target: cloudIcon; property: "opacity"
                        duration: Theme.variantDuration(40, false)
                        easing.type: Easing.InQuad 
                    }
                }
            },
            Transition {
                from: "minimized"; to: ""
                ParallelAnimation {
                    NumberAnimation { 
                        target: window; properties: "width,height"
                        duration: Theme.variantDuration(Theme.expressiveDurations.normal, true)
                        easing.type: Easing.Bezier; easing.bezierCurve: Theme.variantEnterCurve 
                    }
                    NumberAnimation { 
                        target: container; properties: "radius"
                        duration: Theme.variantDuration(Theme.expressiveDurations.normal, true)
                        easing.type: Easing.InOutQuad 
                    }
                    ColorAnimation { 
                        target: container
                        duration: Theme.variantDuration(Theme.expressiveDurations.normal, true) 
                    }
                    NumberAnimation { 
                        target: img; property: "opacity"
                        duration: Theme.variantDuration(Theme.expressiveDurations.normal, true)
                        easing.type: Easing.InQuad 
                    }
                    NumberAnimation { 
                        target: cloudIcon; property: "opacity"
                        duration: Theme.variantDuration(Theme.expressiveDurations.fast, true) 
                    }
                }
            }
        ]
    }
}
