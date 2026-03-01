import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Frame {
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8

        Label {
            text: "Inputs"
            font.bold: true
        }

        TextArea {
            Layout.fillWidth: true
            Layout.fillHeight: true
            placeholderText: "Prompt input migration in progress..."
        }
    }
}
