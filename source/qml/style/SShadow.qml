import QtQuick
import QtQuick.Controls

import gui 1.0

Item {
    id: root
    property var color: COMMON.bg00
    property var shadowColor: "#f0000000"
    property var radius: 16
    property var samples: 16

    Rectangle {
        anchors.fill: parent
        anchors.margins: 1
        color: root.color
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.45)
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.width: 2
        border.color: root.shadowColor
        opacity: 0.2
    }
}
