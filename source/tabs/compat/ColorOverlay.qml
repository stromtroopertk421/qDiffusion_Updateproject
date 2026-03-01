import QtQuick
import QtQuick.Effects

MultiEffect {
    id: root
    property color color: "white"
    colorization: 1.0
    colorizationColor: root.color
}
