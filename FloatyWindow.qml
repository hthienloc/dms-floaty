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
    
    signal closing()
    
    property string imageSource: ""
    property bool isPinned: true 
    property int initialWidth: 400
    
    // Settings from plugin
    property var pluginData: ({}) // Should be passed/synced, but for safety:
    readonly property bool autoMinimize: pluginData.autoMinimize ?? false
    readonly property int minimizeDelay: pluginData.minimizeDelay ?? 3000
    
    property bool isMinimized: false
    property real targetWidth: initialWidth
    property real targetHeight: 300 // Initial placeholder

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

    width: isMinimized ? 48 : targetWidth
    height: isMinimized ? 48 : targetHeight

    // Smooth transitions for size
    Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }
    Behavior on height { NumberAnimation { duration: 300; easing.type: Easing.InOutQuad } }

    Timer {
        id: minimizeTimer
        interval: window.minimizeDelay
        repeat: false
        onTriggered: window.isMinimized = true
    }

    // The Drag Engine (Helper item for Quickshell position sync)
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
        anchors.margins: window.isMinimized ? 0 : 5
        radius: window.isMinimized ? height / 2 : Theme.cornerRadius
        color: window.isMinimized ? Theme.primary : Theme.surfaceContainer
        border.color: window.isMinimized ? "transparent" : Theme.outlineVariant
        border.width: window.isMinimized ? 0 : 1
        clip: true

        // Image View
        Image {
            id: img
            source: window.imageSource
            anchors.fill: parent
            anchors.margins: 2
            fillMode: Image.PreserveAspectFit
            asynchronous: true
            opacity: window.isMinimized ? 0 : 1
            visible: opacity > 0
            
            Behavior on opacity { NumberAnimation { duration: 200 } }

            onStatusChanged: {
                if (status === Image.Ready) {
                    let ratio = implicitHeight / implicitWidth;
                    window.targetHeight = window.targetWidth * ratio;
                }
            }
        }

        // Minimized Icon
        DankIcon {
            name: "cloud"
            anchors.centerIn: parent
            size: Theme.iconSizeSmall
            color: Theme.surface
            opacity: window.isMinimized ? 1 : 0
            visible: opacity > 0
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }

        // Interactions
        MouseArea {
            id: dragArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.SizeAllCursor
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            
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
                }
            }

            onWheel: (wheel) => {
                if (window.isMinimized) return;
                
                let scaleFactor = wheel.angleDelta.y > 0 ? 1.1 : 0.9;
                let newWidth = Math.max(100, Math.min(2000, window.targetWidth * scaleFactor));
                let ratio = img.implicitHeight / img.implicitWidth;
                
                window.targetWidth = newWidth;
                window.targetHeight = newWidth * ratio;
            }
        }
    }
}
