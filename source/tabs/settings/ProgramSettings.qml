import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Frame {
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8

        Label { text: "Program Settings"; font.bold: true }
        Label {
            Layout.fillWidth: true
            text: "Program configuration controls are being rebuilt for Qt 6.10.2."
            wrapMode: Text.WordWrap
        }
    }
}
