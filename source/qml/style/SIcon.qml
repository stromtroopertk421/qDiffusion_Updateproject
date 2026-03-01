import QtQuick
import QtQuick.Controls
import QtQuick.Effects

import gui 1.0

Item {
    property var icon
    property var iconColor: COMMON.bg6
    property var inset: 10
    property var smooth: true
    height: 35
    width: 35

    Image {
        id: img
        source: icon
        width: parent.height - inset
        height: width
        sourceSize: Qt.size(parent.width, parent.height)
        anchors.centerIn: parent
        smooth: parent.smooth
        antialiasing: parent.smooth
        visible: false
    }

    MultiEffect {
        anchors.fill: img
        source: img
        colorization: 1.0
        colorizationColor: iconColor
    }
}
