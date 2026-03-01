import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Frame {
    id: root
    property string title: ""

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 6

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#1a1d23"
            border.color: "#3b4250"
            radius: 4

            Label {
                anchors.centerIn: parent
                text: "Preview"
                opacity: 0.75
            }
        }

        Label {
            Layout.fillWidth: true
            text: root.title
            elide: Text.ElideRight
        }
    }
}
