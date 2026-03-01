import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Frame {
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 8

        Label {
            text: "Outputs"
            font.bold: true
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: "#15181d"
            border.color: "#3a404a"
            radius: 4

            Label {
                anchors.centerIn: parent
                text: "Output gallery panel is being migrated to Qt 6.10.2."
                wrapMode: Text.WordWrap
                width: parent.width - 24
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
