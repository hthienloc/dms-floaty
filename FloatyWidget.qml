import QtQuick
import QtQuick.Controls
import Quickshell
import qs.Common
import qs.Services
import qs.Widgets
import qs.Modules.Plugins
import "./dms-common"

PluginComponent {
    id: root

    pluginId: "floaty"
    pluginService: PluginService

    readonly property var daemonInstance: PluginService.pluginInstances["floaty"] || null
    readonly property int activeWindowCount: daemonInstance ? daemonInstance.localWindowCount : 0

    readonly property bool showBarPill: root.pluginData.showBarPill ?? true
    readonly property bool showHints: root.pluginData.showHints ?? true

    horizontalBarPill: showBarPill ? horizontalPillComp : null
    verticalBarPill: showBarPill ? verticalPillComp : null

    Component {
        id: horizontalPillComp
        Item {
            implicitWidth: horizontalRow.implicitWidth
            implicitHeight: Theme.iconSize
            anchors.verticalCenter: parent.verticalCenter
            
            property bool draggingOver: false

            Row {
                id: horizontalRow
                spacing: Theme.spacingXS
                anchors.verticalCenter: parent.verticalCenter
                scale: draggingOver ? 1.2 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                DankIcon {
                    name: "cloud"
                    size: Theme.iconSizeSmall
                    color: draggingOver ? Theme.primary : (root.activeWindowCount > 0 ? Theme.primary : Theme.surfaceText)
                    anchors.verticalCenter: parent.verticalCenter
                }
                StyledText {
                    text: root.activeWindowCount
                    visible: root.activeWindowCount > 0
                    color: Theme.primary
                    font.pixelSize: Theme.fontSizeSmall
                    font.bold: true
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            DropArea {
                anchors.fill: parent
                onEntered: draggingOver = true
                onExited: draggingOver = false
                onDropped: (drop) => {
                    draggingOver = false;
                    if (daemonInstance) {
                        if (drop.hasUrls) {
                            drop.urls.forEach(url => daemonInstance.spawnWindow(url.toString()));
                        } else if (drop.hasText) {
                            daemonInstance.spawnWindow(drop.text);
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton && daemonInstance) {
                        daemonInstance.selectFileAndFloat();
                    }
                }
            }
        }
    }

    Component {
        id: verticalPillComp
        Item {
            implicitWidth: Theme.iconSize
            implicitHeight: verticalCol.implicitHeight
            anchors.horizontalCenter: parent.horizontalCenter

            property bool draggingOver: false

            Column {
                id: verticalCol
                spacing: 2
                anchors.horizontalCenter: parent.horizontalCenter
                scale: draggingOver ? 1.2 : 1.0
                Behavior on scale { NumberAnimation { duration: 200; easing.type: Easing.OutBack } }

                DankIcon {
                    name: "cloud"
                    size: Theme.iconSizeSmall
                    color: draggingOver ? Theme.primary : (root.activeWindowCount > 0 ? Theme.primary : Theme.surfaceText)
                    anchors.horizontalCenter: parent.horizontalCenter
                }
                StyledText {
                    text: root.activeWindowCount
                    visible: root.activeWindowCount > 0
                    color: Theme.primary
                    font.pixelSize: Theme.fontSizeSmall - 2
                    font.bold: true
                    anchors.horizontalCenter: parent.horizontalCenter
                }
            }

            DropArea {
                anchors.fill: parent
                onEntered: draggingOver = true
                onExited: draggingOver = false
                onDropped: (drop) => {
                    draggingOver = false;
                    if (daemonInstance) {
                        if (drop.hasUrls) {
                            drop.urls.forEach(url => daemonInstance.spawnWindow(url.toString()));
                        } else if (drop.hasText) {
                            daemonInstance.spawnWindow(drop.text);
                        }
                    }
                }
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.MiddleButton
                cursorShape: Qt.PointingHandCursor
                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton && daemonInstance) {
                        daemonInstance.selectFileAndFloat();
                    }
                }
            }
        }
    }

    pillRightClickAction: function() {
        if (daemonInstance) {
            daemonInstance.smartPaste();
        }
    }

    popoutContent: Component {
        PopoutComponent {
            id: popout
            width: 280
            headerText: "Floaty"
            detailsText: "Reference images on top"
            showCloseButton: true

            property var parentPopout: null

            PluginShortcut {
                id: shortcuts
                parentPopout: popout.parentPopout
                onOpened: {
                    Qt.callLater(() => {
                        urlInput.forceActiveFocus();
                    });
                }
                onEnterPressed: {
                    if (urlInput.text !== "" && daemonInstance) {
                        daemonInstance.spawnWindow(urlInput.text);
                        root.closePopout();
                    }
                }
                onEscapePressed: root.closePopout()
            }
            
            Item {
                width: parent.width
                implicitHeight: mainCol.implicitHeight

                DropArea {
                    anchors.fill: parent
                    onDropped: (drop) => {
                        if (daemonInstance) {
                            if (drop.hasUrls) {
                                drop.urls.forEach(url => daemonInstance.spawnWindow(url.toString()));
                            } else if (drop.hasText) {
                                daemonInstance.spawnWindow(drop.text);
                            }
                        }
                        root.closePopout();
                    }
                }

                Column {
                    id: mainCol
                    width: parent.width
                    spacing: Theme.spacingM
                    
                    Row {
                        width: parent.width
                        spacing: Theme.spacingS
                        
                        DankButton {
                            text: I18n.tr("Clipboard")
                            width: (parent.width - Theme.spacingS) / 2
                            iconName: "content_paste"
                            backgroundColor: Theme.primaryContainer
                            textColor: Theme.primary
                            onClicked: {
                                if (daemonInstance) {
                                    daemonInstance.floatFromClipboard();
                                }
                                root.closePopout();
                            }
                        }
                        
                        DankButton {
                            text: I18n.tr("Select File")
                            width: (parent.width - Theme.spacingS) / 2
                            iconName: "folder_open"
                            backgroundColor: Theme.surfaceContainerHighest
                            textColor: Theme.surfaceText
                            onClicked: {
                                if (daemonInstance) {
                                    daemonInstance.selectFileAndFloat();
                                }
                                root.closePopout();
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: Theme.spacingS
                        visible: root.activeWindowCount > 0

                        DankButton {
                            text: I18n.tr("Toggle All")
                            width: (parent.width - Theme.spacingS) / 2
                            iconName: "unfold_more"
                            backgroundColor: Theme.surfaceContainerHighest
                            textColor: Theme.surfaceText
                            onClicked: {
                                if (daemonInstance) {
                                    daemonInstance.toggleMinimizeAll();
                                }
                                root.closePopout();
                            }
                        }

                        DankButton {
                            text: I18n.tr("Close All")
                            width: (parent.width - Theme.spacingS) / 2
                            iconName: "delete_sweep"
                            backgroundColor: Theme.error
                            textColor: Theme.surfaceText
                            onClicked: {
                                if (daemonInstance) {
                                    daemonInstance.closeAllWindows();
                                }
                                root.closePopout();
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: Theme.spacingS
                        
                        StyledText {
                            text: I18n.tr("Float from Link or Path")
                            font.pixelSize: Theme.fontSizeSmall
                            font.bold: true
                            color: Theme.surfaceVariantText
                        }
                        
                        Row {
                            width: parent.width
                            spacing: Theme.spacingS
                            
                            DankTextField {
                                id: urlInput
                                width: parent.width - 44 - Theme.spacingS
                                placeholderText: "https://... or /path/..."
                                onAccepted: {
                                    if (text !== "" && daemonInstance) {
                                        daemonInstance.spawnWindow(text);
                                        root.closePopout();
                                    }
                                }
                            }
                            
                            DankButton {
                                width: 44
                                iconName: "add"
                                backgroundColor: Theme.primaryContainer
                                textColor: Theme.primary
                                onClicked: {
                                    if (urlInput.text !== "" && daemonInstance) {
                                        daemonInstance.spawnWindow(urlInput.text);
                                        root.closePopout();
                                    }
                                }
                            }
                        }
                    }

                    HintSection {
                        showHints: root.showHints
                        
                        HintItem { icon: "open_with"; text: I18n.tr("Left Click + Drag: Move window") }
                        HintItem { icon: "aspect_ratio"; text: I18n.tr("Scroll Wheel: Resize image") }
                        HintItem { icon: "minimize"; text: I18n.tr("Right Click: Toggle minimize") }
                        HintItem { icon: "close"; text: I18n.tr("Middle Click: Close window") }
                        HintItem { icon: "add_photo_alternate"; text: I18n.tr("Drop image/link: Quick float") }
                        HintItem { icon: "folder_open"; text: I18n.tr("Middle Click Icon: Select file to float") }
                        HintItem { icon: "bolt"; text: I18n.tr("Right Click Icon: Fast paste image/link") }
                        HintItem { icon: "picture_as_pdf"; text: I18n.tr("PDF: Enter pages like 1, 1-3, or 1 3 5") }
                    }
                }
            }
        }
    }
}
