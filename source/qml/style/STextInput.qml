import QtQuick
import QtQuick.Controls
import gui 1.0

TextInput {
                
    property var pointSize: 10.8
    property var monospace: false

    font.family: monospace ? COMMON.monoFont : COMMON.sansFont
    font.pointSize: pointSize * COORDINATOR.scale
    color: COMMON.fg0
    selectByMouse: true

    Component.onCompleted: {
        if(font.bold) {
            font.letterSpacing = -1.0
        }
    }
}