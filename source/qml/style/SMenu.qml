import QtQuick
import QtQuick.Controls
import QtQuick.Effects

import gui 1.0

Menu {
    id: root
    readonly property real menuItemSize: 20
    topPadding: 2
    bottomPadding: 2
    property var clipShadow: false

    property var pointSize: 10.6
    property var color: COMMON.fg1

    delegate: SMenuItem {
        pointSize: root.pointSize
        color: root.color
        menuItemSize: root.menuItemSize
    }

    background: Item {
        implicitWidth: 150
        implicitHeight: menuItemSize

        Rectangle {
            id: bg
            anchors.fill: parent
            color: COMMON.bg3
            border.width: 1
            border.color: COMMON.bg4
        }

        MultiEffect {
            anchors.fill: bg
            source: bg
            shadowEnabled: true
            shadowColor: "#d0000000"
            shadowBlur: 0.45
            shadowOpacity: 0.85
            shadowHorizontalOffset: 0
            shadowVerticalOffset: 2
        }
    }
}
