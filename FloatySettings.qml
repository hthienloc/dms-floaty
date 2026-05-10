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
        label: "Default Image Size"
        description: "The initial width for newly floated images (pixels)"
        defaultValue: 400
        minimum: 100
        maximum: 1000
        unit: "px"
        rightIcon: "aspect_ratio"
    }
}
