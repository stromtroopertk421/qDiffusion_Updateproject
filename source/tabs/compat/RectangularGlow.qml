import QtQuick

Item {
    id: root
    property Item source
    property real glowRadius: 0
    property real spread: 0
    property color color: "transparent"
    property real cornerRadius: 0

    anchors.fill: source ? source : undefined

    Rectangle {
        anchors.fill: parent
        anchors.margins: -Math.max(1, root.glowRadius * Math.max(0.2, root.spread))
        radius: Math.max(0, root.cornerRadius + root.glowRadius * 0.5)
        color: "transparent"
        border.width: Math.max(1, root.glowRadius * 0.6)
        border.color: root.color
        opacity: 0.75
    }
}
