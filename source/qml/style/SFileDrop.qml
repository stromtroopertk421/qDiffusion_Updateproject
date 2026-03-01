import QtQuick
import QtQuick.Controls
import QtQuick.Effects

import gui 1.0

AdvancedDropArea {
    id: root
    property var label: "Drop to load file"
    property var icon: true

    Item {
        visible: parent.containsDrag
        anchors.fill: parent

        Rectangle { anchors.fill: parent; color: "black"; opacity: 0.3 }

        SGlow {
            opacity: 0.3
            visible: dropText.visible
            target: dropText
            source: dropText
            radius: 4
            samples: 4
            color: "#000000"
        }

        SText {
            id: dropText
            text: root.label
            visible: text !== ""
            anchors.horizontalCenter: dropIcon.horizontalCenter
            anchors.bottom: dropIcon.top
            anchors.bottomMargin: 5
            color: COMMON.fg2
            pointSize: 10
            font.bold: true
        }

        SGlow {
            visible: dropIcon.visible
            opacity: 0.3
            target: dropIcon
            source: dropIcon
            radius: 4
            samples: 4
            color: "#000000"
        }

        Image {
            id: dropIcon
            source: "qrc:/icons/download.svg"
            height: 30
            width: height
            sourceSize: Qt.size(width * 1.25, height * 1.25)
            anchors.centerIn: parent
            smooth: true
            visible: false
        }

        MultiEffect {
            visible: root.icon
            anchors.fill: dropIcon
            source: dropIcon
            colorization: 1.0
            colorizationColor: COMMON.fg2
        }
    }
}
