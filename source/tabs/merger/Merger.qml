import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    anchors.fill: parent

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 10

        Label {
            text: "Merger"
            font.pixelSize: 22
            font.bold: true
        }

        RowLayout {
            Layout.fillWidth: true
            Button {
                text: "Merge"
                onClicked: MERGER.merge()
            }
            Button {
                text: "Queue"
                onClicked: MERGER.enqueue()
            }
            Button {
                text: "Cancel"
                onClicked: MERGER.cancel()
            }
        }

        Frame {
            Layout.fillWidth: true
            Layout.fillHeight: true

            Label {
                anchors.centerIn: parent
                text: "Model selection grids and merge recipes are being migrated to Qt 6.10.2."
                width: parent.width - 24
                wrapMode: Text.WordWrap
                horizontalAlignment: Text.AlignHCenter
            }
        }
    }
}
