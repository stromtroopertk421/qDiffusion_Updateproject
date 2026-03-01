import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Frame {
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8

        Label { text: "Remote Settings"; font.bold: true }
        Label {
            Layout.fillWidth: true
            text: "Remote profile editor is not fully re-implemented yet."
            wrapMode: Text.WordWrap
        }
    }
}
