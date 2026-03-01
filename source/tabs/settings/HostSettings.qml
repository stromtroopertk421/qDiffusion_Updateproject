import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Frame {
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8

        Label { text: "Host Settings"; font.bold: true }
        Label {
            Layout.fillWidth: true
            text: "Host/server controls are temporarily simplified during migration."
            wrapMode: Text.WordWrap
        }
    }
}
