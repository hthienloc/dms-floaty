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

    // Dynamic width/height handled by states
    width: targetWidth
    height: targetHeight

    Timer {
        id: minimizeTimer
        interval: window.minimizeDelay
        repeat: false
        onTriggered: window.isMinimized = true
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

    // State Management for smooth transitions
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
                NumberAnimation { target: window; properties: "width,height"; duration: 400; easing.type: Easing.InOutBack }
                NumberAnimation { target: container; properties: "radius"; duration: 400; easing.type: Easing.InOutQuad }
                ColorAnimation { target: container; duration: 400 }
                NumberAnimation { target: img; property: "opacity"; duration: 200 }
                NumberAnimation { target: cloudIcon; property: "opacity"; duration: 300; easing.type: Easing.InQuad }
            }
        },
        Transition {
            from: "minimized"; to: ""
            ParallelAnimation {
                NumberAnimation { target: window; properties: "width,height"; duration: 400; easing.type: Easing.OutBack }
                NumberAnimation { target: container; properties: "radius"; duration: 400; easing.type: Easing.InOutQuad }
                ColorAnimation { target: container; duration: 400 }
                NumberAnimation { target: img; property: "opacity"; duration: 300; easing.type: Easing.InQuad }
                NumberAnimation { target: cloudIcon; property: "opacity"; duration: 150 }
            }
        }
    ]
}
