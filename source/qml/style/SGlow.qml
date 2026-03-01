import QtQuick
import QtQuick.Effects

Item {
    id: root
    required property Item target
    property Item source: target
    property real radius: 5
    property real samples: 8
    property color color: "black"
    property real spread: 0.2
    property real cornerRadius: 10
    opacity: 0.5

    anchors.fill: target

    MultiEffect {
        anchors.fill: source
        source: root.source
        shadowEnabled: true
        shadowColor: root.color
        shadowBlur: Math.min(1.0, root.radius / 12.0)
        shadowOpacity: Math.max(0.0, Math.min(1.0, root.opacity))
        shadowHorizontalOffset: 0
        shadowVerticalOffset: 0
        blurEnabled: true
        blur: Math.min(1.0, root.radius / 16.0)
    }
}
