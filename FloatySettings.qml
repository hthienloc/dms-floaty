import QtQuick
import qs.Common
import qs.Widgets
import qs.Modules.Plugins

PluginSettings {
    id: root
    pluginId: "floaty"

    StyledText {
        width: parent.width
        text: "Floaty Settings"
        font.pixelSize: Theme.fontSizeLarge
        font.weight: Font.Bold
        color: Theme.surfaceText
    }

    StyledText {
        width: parent.width
        text: "Configure the default behavior for floating images."
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.surfaceVariantText
        wrapMode: Text.WordWrap
    }

    StyledRect {
        width: parent.width
        height: 1
        color: Theme.surfaceVariant
    }

    StyledText {
        text: "Appearance"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    SliderSetting {
        settingKey: "initialScale"
        label: "Initial Image Size"
        minimumValue: 100
        maximumValue: 800
        stepSize: 50
        unit: "px"
    }

    StyledRect {
        width: parent.width
        height: 1
        color: Theme.surfaceVariant
    }

    StyledText {
        text: "Auto Minimize"
        font.pixelSize: Theme.fontSizeMedium
        font.weight: Font.DemiBold
        color: Theme.surfaceText
    }

    SwitchSetting {
        id: autoMinimizeSwitch
        settingKey: "autoMinimize"
        label: "Minimize when not hovered"
        description: "Shrink to an icon after a delay when mouse leaves the image"
    }

    SliderSetting {
        settingKey: "minimizeDelay"
        label: "Minimize Delay"
        minimumValue: 1000
        maximumValue: 10000
        stepSize: 500
        unit: "ms"
        // Use a more robust check for the enabled state
        enabled: autoMinimizeSwitch.checked
    }
}
