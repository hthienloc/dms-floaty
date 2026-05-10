import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
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
    
    // Direct position control
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

    width: 300
    height: 300
    color: "transparent"

    // The Drag Engine
    Item {
        id: dragTarget
        x: window.xPos
        y: window.yPos
        
        // Update the window position only when actively dragged
        onXChanged: {
            if (dragArea.drag.active) window.xPos = x
        }
        onYChanged: {
            if (dragArea.drag.active) window.yPos = y
        }
    }

    // Visual Content
    StyledRect {
        id: container
        anchors.fill: parent
        anchors.margins: 5
        radius: Theme.cornerRadius
        color: Theme.surfaceContainer
        border.color: Theme.outlineVariant
        border.width: 1
        
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: ShaderEffectSource {
                sourceItem: Rectangle {
                    width: container.width
                    height: container.height
                    radius: container.radius
                }
            }
        }

        Image {
            id: img
            anchors.fill: parent
            anchors.margins: 2
            source: window.imageSource
            fillMode: Image.PreserveAspectFit
            asynchronous: true
        
            onStatusChanged: {
                if (status === Image.Ready) {
                    let ratio = img.implicitWidth / img.implicitHeight;
                    let targetW, targetH;
                    
                    // Use initialWidth from settings
                    targetW = Math.max(100, window.initialWidth);
                    targetH = targetW / ratio;
                    
                    window.width = targetW;
                    window.height = targetH;
                    
                    // Initial sync
                    dragTarget.x = window.xPos;
                    dragTarget.y = window.yPos;
                }
            }

            StyledText {
                anchors.centerIn: parent
                text: "Loading..."
                visible: img.status === Image.Loading
                color: Theme.surfaceVariantText
            }
        }
    }

    // Interaction Area - MOVED TO BOTTOM TO BE ON TOP
    MouseArea {
        id: dragArea
        anchors.fill: parent
        cursorShape: Qt.SizeAllCursor
        acceptedButtons: Qt.AllButtons
        hoverEnabled: true
        
        drag.target: dragTarget
        drag.axis: Drag.XAndYAxis
        drag.threshold: 0
        
        onPressed: (mouse) => {
            if (mouse.button === Qt.RightButton) {
                window.closing()
                window.destroy()
            }
        }

        onWheel: (wheel) => {
            let delta = wheel.angleDelta.y;
            if (delta === 0) return;
            
            let zoomFactor = delta > 0 ? 1.1 : 0.9;
            let oldW = window.width;
            let oldH = window.height;
            let newW = oldW * zoomFactor;
            let newH = oldH * zoomFactor;
            
            if (newW >= 100 && newW <= 2000) {
                // Adjust position to simulate center zoom
                let dx = (newW - oldW) / 2;
                let dy = (newH - oldH) / 2;
                window.xPos -= dx;
                window.yPos -= dy;
                
                // Sync the dragTarget so it doesn't jump on next drag
                dragTarget.x = window.xPos;
                dragTarget.y = window.yPos;
                
                window.width = newW;
                window.height = newH;
            }
            wheel.accepted = true;
        }
    }
}
