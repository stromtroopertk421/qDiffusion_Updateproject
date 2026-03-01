import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Frame {
    id: root
    property alias title: titleLabel.text

    background: Rectangle {
        color: "#20242b"
        radius: 6
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8

        Label {
            id: titleLabel
            text: "Workspace"
            font.bold: true
        }

        Label {
            Layout.fillWidth: true
            Layout.fillHeight: true
            text: "Canvas and region controls are being reintroduced with the Qt 6 style layer."
            wrapMode: Text.WordWrap
            verticalAlignment: Text.AlignVCenter
        }
    }
}
